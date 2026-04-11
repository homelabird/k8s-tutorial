/**
 * Exam Service
 * Handles all business logic for exam operations
 */

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');
const redisClient = require('../utils/redisClient');
const jumphostService = require('./jumphostService');
const MetricService = require('./metricService');

function loadLabsIndex() {
  const labsPath = path.join(process.cwd(), 'assets', 'exams', 'labs.json');

  if (!fs.existsSync(labsPath)) {
    throw new Error(`Labs data file not found at ${labsPath}`);
  }

  const labsData = JSON.parse(fs.readFileSync(labsPath, 'utf8'));
  return labsData.labs || [];
}

function resolveExamDefinition(examData = {}) {
  if (examData.assetPath) {
    return { ...examData };
  }

  if (!examData.examId) {
    throw new Error('Exam definition is missing assetPath and examId');
  }

  const labs = loadLabsIndex();
  const labDefinition = labs.find((lab) => lab.id === examData.examId);

  if (!labDefinition) {
    throw new Error(`Exam definition not found for examId: ${examData.examId}`);
  }

  return {
    ...labDefinition,
    ...examData
  };
}

function loadExamConfig(assetPath) {
  const configPath = path.join(process.cwd(), assetPath, 'config.json');

  if (!fs.existsSync(configPath)) {
    throw new Error(`Config file not found at path: ${configPath}`);
  }

  return JSON.parse(fs.readFileSync(configPath, 'utf8'));
}

function loadExamQuestionsFromAsset(assetPath, config = {}) {
  const questionsFilePath = config.questions || 'assessment.json';
  const fullQuestionsPath = path.join(process.cwd(), assetPath, questionsFilePath);

  if (!fs.existsSync(fullQuestionsPath)) {
    throw new Error(`Questions file not found at path: ${fullQuestionsPath}`);
  }

  return JSON.parse(fs.readFileSync(fullQuestionsPath, 'utf8'));
}

function buildEnvironmentPlan(config = {}, rawQuestions = []) {
  const defaultWorkerNodes = parseInt(config.workerNodes, 10) || 1;
  const configuredEnvironments = config.environments || {};
  const environments = [];

  environments.push({
    id: 'shared',
    sshHost: 'jumphost',
    sshAlias: 'ckad9999',
    clusterName: 'cluster',
    k8sApiServerHost: 'k8s-api-server',
    kubeApiPort: 6443,
    workerNodes: defaultWorkerNodes,
    ...configuredEnvironments.shared,
    questionIds: []
  });

  for (const [environmentId, environmentConfig] of Object.entries(configuredEnvironments)) {
    if (environmentId === 'shared') {
      continue;
    }

    environments.push({
      id: environmentId,
      sshHost: environmentConfig.sshHost || environmentId,
      sshAlias: environmentConfig.sshAlias || environmentId,
      clusterName: environmentConfig.clusterName || environmentId,
      k8sApiServerHost: environmentConfig.k8sApiServerHost || 'k8s-api-server',
      kubeApiPort: environmentConfig.kubeApiPort || environmentConfig.apiPort || 6443,
      workerNodes: parseInt(environmentConfig.workerNodes, 10) || defaultWorkerNodes,
      ...environmentConfig,
      questionIds: []
    });
  }

  for (const question of rawQuestions) {
    const environmentId = question.environmentId || 'shared';
    const environment = environments.find((candidate) => candidate.id === environmentId);

    if (!environment) {
      throw new Error(`Environment '${environmentId}' is not defined in config.json`);
    }

    environment.questionIds.push(String(question.id));
  }

  return { environments };
}

function applyEnvironmentPlanToQuestions(rawQuestions = [], environmentPlan = {}) {
  const environments = Array.isArray(environmentPlan.environments)
    ? environmentPlan.environments
    : [];

  return rawQuestions.map((question) => {
    const environmentId = question.environmentId || 'shared';
    const environment = environments.find((candidate) => candidate.id === environmentId);

    if (!environment) {
      return { ...question, environmentId };
    }

    return {
      ...question,
      environmentId,
      machineHostname: environment.sshAlias || question.machineHostname
    };
  });
}

async function releaseCurrentExamLock(examId) {
  try {
    const currentExamId = await redisClient.getCurrentExamId();
    if (currentExamId === examId) {
      await redisClient.deleteCurrentExamId();
    }
  } catch (error) {
    logger.error(`Failed to release current exam lock for exam ${examId}`, {
      error: error.message
    });
  }
}

/**
 * Create a new exam
 * @param {Object} examData - The exam data
 * @returns {Promise<Object>} Result object with success status and data
 */
async function createExam(examData) {
  try {
    // Check if there's already an active exam
    const currentExamId = await redisClient.getCurrentExamId();
    
    // If currentExamId exists, don't allow creating a new exam
    if (currentExamId) {
      logger.warn(`Attempted to create a new exam while exam ${currentExamId} is still active`);
      return {
        success: false,
        error: 'Exam already exists',
        message: 'Only one exam can be active at a time. End the current exam before creating a new one.',
        currentExamId
      };
    }
    
    const examId = uuidv4();
    const resolvedExamData = resolveExamDefinition(examData);
    
    // fetch exam config from the asset path and append it to the examData
    resolvedExamData.config = loadExamConfig(resolvedExamData.assetPath);
    const rawQuestions = loadExamQuestionsFromAsset(resolvedExamData.assetPath, resolvedExamData.config);
    resolvedExamData.environmentPlan = buildEnvironmentPlan(
      resolvedExamData.config,
      rawQuestions.questions || []
    );
    delete resolvedExamData.answers;

    //persist created at time
    resolvedExamData.createdAt = new Date().toISOString();
    // Store exam information in Redis
    await redisClient.persistExamInfo(examId, resolvedExamData);
    
    // Set initial exam status
    await redisClient.persistExamStatus(examId, 'CREATED');
    
    // Set as current exam ID
    await redisClient.setCurrentExamId(examId);
    
    logger.info(`Exam created successfully with ID: ${examId}`);
    
    // Set up the exam environment asynchronously
    // This will happen in the background while the response is sent back to the client
    setupExamEnvironmentAsync(examId, resolvedExamData.environmentPlan);
    
    // send metrics to metric server
    MetricService.sendMetrics(examId, {
      category: resolvedExamData.category,
      labId: resolvedExamData.config.lab,
      examName: resolvedExamData.name,
      event: {
        userAgent: resolvedExamData.userAgent
      }
    });

    return {
      success: true,
      data: {
        id: examId,
        status: 'CREATED',
        message: 'Exam created successfully and environment preparation started'
      }
    };
  } catch (error) {
    logger.error('Error creating exam', { error: error.message });
    return {
      success: false,
      error: 'Failed to create exam',
      message: error.message
    };
  }
}

/**
 * Set up the exam environment asynchronously
 * This function runs in the background and doesn't block the response
 * 
 * @param {string} examId - The exam ID
 * @param {Object} environmentPlan - Environment routing plan
 */
async function setupExamEnvironmentAsync(examId, environmentPlan) {
  try {
    // Call the jumphost service to set up the exam environment
    const result = await jumphostService.setupExamEnvironment(examId, environmentPlan);     
    
    if (!result.success) {
      logger.error(`Failed to set up exam environment for exam ${examId}`, {
        error: result.error,
        details: result.details
      });
      await releaseCurrentExamLock(examId);
      // The jumphostService already updates the exam status on failure
      return;
    }
    
    logger.info(`Exam environment set up successfully for exam ${examId}`);
    // The jumphostService already updates the exam status on success
  } catch (error) {
    logger.error(`Unexpected error setting up exam environment for exam ${examId}`, {
      error: error.message
    });
    
    // Update exam status to PREPARATION_FAILED if not already done
    try {
      const currentStatus = await redisClient.getExamStatus(examId);
      if (currentStatus !== 'PREPARATION_FAILED') {
        await redisClient.persistExamStatus(examId, 'PREPARATION_FAILED');
      }
      await releaseCurrentExamLock(examId);
    } catch (statusError) {
      logger.error(`Failed to update exam status for exam ${examId}`, {
        error: statusError.message
      });
    }
  }
}

/**
 * Get the current active exam
 * @returns {Promise<Object>} Result object with success status and data
 */
async function getCurrentExam() {
  try {
    // Get the current exam ID
    const examId = await redisClient.getCurrentExamId();
    
    // based on the path include 
    if (!examId) {
      logger.info('No current exam is set');
      return {
        success: false,
        error: 'Not Found',
        message: 'No current exam is active'
      };
    }
    
    // Get exam information and status
    const examInfo = await redisClient.getExamInfo(examId);
    const examStatus = await redisClient.getExamStatus(examId);
    
    return {
      success: true,
      data: {
        id: examId,
        status: examStatus,
        info: examInfo
      }
    };
  } catch (error) {
    logger.error('Error retrieving current exam', { error: error.message });
    return {
      success: false,
      error: 'Failed to retrieve current exam',
      message: error.message
    };
  }
}

/**
 * Get exam assets
 * @param {string} examId - The exam ID
 * @returns {Promise<Object>} Result object with success status and data
 */
async function getExamAssets(examId) {
  try {
    // Check if exam exists in Redis
    const examInfo = await redisClient.getExamInfo(examId);
    
    if (!examInfo) {
      logger.error(`Exam not found with ID: ${examId}`);
      return {
        success: false,
        error: 'Not Found',
        message: 'Exam not found'
      };
    }
    
    // Placeholder implementation - will be implemented later
    return {
      success: true,
      data: {
        examId,
        assets: []
      }
    };
  } catch (error) {
    logger.error('Error retrieving exam assets', { error: error.message });
    return {
      success: false,
      error: 'Failed to retrieve exam assets',
      message: error.message
    };
  }
}

/**
 * Get exam questions
 * @param {string} examId - The exam ID
 * @returns {Promise<Object>} Result object with success status and data
 */
async function getExamQuestions(examId) {
  try {
    // Check if exam exists and get status
    const examStatus = await redisClient.getExamStatus(examId);
    const examInfo = await redisClient.getExamInfo(examId);
    
    if (!examStatus || !examInfo) {
      logger.error(`Exam not found with ID: ${examId}`);
      return {
        success: false,
        error: 'Not Found',
        message: 'Exam not found'
      };
    }
    
    // Get asset path from exam info
    const assetPath = examInfo.assetPath;
    if (!assetPath) {
      logger.error(`Asset path not found for exam: ${examId}`);
      return {
        success: false,
        error: 'Configuration Error',
        message: 'Exam asset path not defined'
      };
    }
    
    const config = examInfo.config || loadExamConfig(assetPath);
    const questions = loadExamQuestionsFromAsset(assetPath, config);
    const environmentPlan = examInfo.environmentPlan || buildEnvironmentPlan(config, questions.questions || []);
    const enrichedQuestions = applyEnvironmentPlanToQuestions(questions.questions || [], environmentPlan);
    
    logger.info(`Successfully retrieved questions for exam ${examId}`);
    
    return {
      success: true,
      data: {
        questions: enrichedQuestions
      }
    };
  } catch (error) {
    logger.error('Error retrieving exam questions', { error: error.message });
    return {
      success: false,
      error: 'Failed to retrieve exam questions',
      message: error.message
    };
  }
}

/**
 * Evaluate an exam
 * @param {string} examId - The exam ID
 * @param {Object} evaluationData - The evaluation data
 * @returns {Promise<Object>} Result object with success status and data
 */
async function evaluateExam(examId, evaluationData) {
  try {
    // Get exam data and question information
    const examInfo = await redisClient.getExamInfo(examId);
    if (!examInfo) {
      throw new Error(`Exam not found with ID: ${examId}`);
    }
    
    // Get exam questions data
    const questionsResponse = await getExamQuestions(examId);
    if (!questionsResponse.success) {
      throw new Error('Failed to get exam questions');
    }
    
    const environmentPlan = examInfo.environmentPlan || buildEnvironmentPlan(
      examInfo.config || loadExamConfig(examInfo.assetPath),
      questionsResponse.data.questions || []
    );

    // Update exam status to EVALUATING only after confirming the exam exists
    // and the question payload can be loaded successfully.
    await redisClient.updateExamStatus(examId, 'EVALUATING');

    MetricService.sendMetrics(examId, {
      event: {
        examEvaluationState: 'EVALUATING'
      }
    });
    
    // Start evaluation asynchronously using Promise
    // This will happen in the background while the response is sent back to the client
    Promise.resolve().then(async () => {
      try {
        // Call the jumphost service to perform the evaluation
        await jumphostService.evaluateExamOnJumphost(
          examId,
          questionsResponse.data.questions,
          environmentPlan
        );
      } catch (error) {
        logger.error(`Error in async exam evaluation for exam ${examId}`, { error: error.message });
        // Update exam status to EVALUATION_FAILED
        await redisClient.updateExamStatus(examId, 'EVALUATION_FAILED');
      }
    });
    
    return {
      success: true,
      data: {
        examId,
        status: 'EVALUATING',
        message: 'Exam evaluation started'
      }
    };
  } catch (error) {
    logger.error('Error starting exam evaluation', { error: error.message });
    return {
      success: false,
      error: 'Failed to start exam evaluation',
      message: error.message
    };
  }
}

/**
 * Get exam evaluation result
 * @param {string} examId - The exam ID
 * @returns {Promise<Object>} Result object with success status and data
 */
async function getExamResult(examId) {
  try {
    const result = await redisClient.getExamResult(examId);
    if (!result) {
      logger.warn(`No evaluation result found for exam ${examId}`);
      return {
        success: false,
        error: 'Not Found',
        message: 'Exam evaluation result not found'
      };
    }
    
    return {
      success: true,
      data: result
    };
  } catch (error) {
    logger.error('Error retrieving exam result', { error: error.message });
    return {
      success: false,
      error: 'Failed to retrieve exam result',
      message: error.message
    };
  }
}

/**
 * End an exam
 * @param {string} examId - The exam ID
 * @returns {Promise<Object>} Result object with success status and data
 */
async function endExam(examId) {
  try {
    // Get current exam ID to verify this is the active exam
    const currentExamId = await redisClient.getCurrentExamId();
    const examInfo = await redisClient.getExamInfo(examId);
    
    if (currentExamId !== examId) {
      logger.warn(`Attempted to end exam ${examId} but current exam is ${currentExamId || 'not set'}`);
    }

    // Clean up the exam environment
    try {
      const cleanupResult = await jumphostService.cleanupExamEnvironment(
        examId,
        examInfo?.environmentPlan || {}
      );

      if (!cleanupResult?.success) {
        return {
          success: false,
          error: 'Failed to end exam',
          message: cleanupResult?.error || cleanupResult?.message || 'Exam cleanup failed'
        };
      }

      // Clear the current exam info only after cleanup succeeds.
      await redisClient.deleteCurrentExamId();
      await redisClient.deleteAllExamData(examId);
    } catch (cleanupError) {
      logger.error(`Error cleaning up exam environment for exam ${examId}`, {
        error: cleanupError.message
      });
      return {
        success: false,
        error: 'Failed to end exam',
        message: cleanupError.message
      };
    }
    
    logger.info(`Exam ${examId} completed`);
    
    return {
      success: true,
      data: {
        examId,
        status: 'COMPLETED',
        message: 'Exam completed successfully'
      }
    };
  } catch (error) {
    logger.error('Error ending exam', { error: error.message });
    return {
      success: false,
      error: 'Failed to end exam',
      message: error.message
    };
  }
}

module.exports = {
  createExam,
  getCurrentExam,
  getExamAssets,
  getExamQuestions,
  evaluateExam,
  endExam,
  getExamResult
}; 
