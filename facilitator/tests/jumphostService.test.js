const sshService = require('../src/services/sshService');
const redisClient = require('../src/utils/redisClient');
const remoteDesktopService = require('../src/services/remoteDesktopService');
const MetricService = require('../src/services/metricService');
const jumphostService = require('../src/services/jumphostService');

jest.mock('../src/services/sshService', () => ({
  executeCommand: jest.fn()
}));

jest.mock('../src/utils/redisClient', () => ({
  persistExamStatus: jest.fn(),
  updateExamStatus: jest.fn()
}));

jest.mock('../src/services/remoteDesktopService', () => ({
  restartVncSession: jest.fn()
}));

jest.mock('../src/services/metricService', () => ({
  sendMetrics: jest.fn()
}));

jest.mock('../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  http: jest.fn()
}));

const sharedEnvironmentPlan = {
  environments: [
    {
      id: 'shared',
      sshHost: 'jumphost',
      sshAlias: 'ckad9999',
      clusterName: 'cluster',
      k8sApiServerHost: 'k8s-api-server',
      kubeApiPort: 6443,
      workerNodes: 2,
      questionIds: ['1', '2']
    }
  ]
};

describe('Jumphost Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    remoteDesktopService.restartVncSession.mockResolvedValue();
    MetricService.sendMetrics.mockResolvedValue();
  });

  describe('setupExamEnvironment', () => {
    it('prepares the environment and marks the exam ready', async () => {
      sshService.executeCommand.mockResolvedValueOnce({
        exitCode: 0,
        stdout: 'Environment prepared successfully',
        stderr: ''
      });

      const result = await jumphostService.setupExamEnvironment('test-exam-id', sharedEnvironmentPlan);

      expect(redisClient.persistExamStatus).toHaveBeenNthCalledWith(1, 'test-exam-id', 'PREPARING');
      expect(redisClient.persistExamStatus).toHaveBeenNthCalledWith(2, 'test-exam-id', 'READY');
      expect(remoteDesktopService.restartVncSession).toHaveBeenCalledTimes(1);
      expect(sshService.executeCommand).toHaveBeenCalledWith(
        "prepare-exam-env 2 'test-exam-id' 'cluster' '1,2' '6443' 'k8s-api-server'",
        { host: 'jumphost' }
      );
      expect(MetricService.sendMetrics).toHaveBeenCalledWith('test-exam-id', {
        event: {
          examLabState: 'READY'
        }
      });
      expect(result).toEqual({
        success: true,
        message: 'Exam environment prepared successfully',
        details: {
          stdout: 'Environment prepared successfully'
        }
      });
    });

    it('marks preparation as failed when the jumphost command fails', async () => {
      sshService.executeCommand.mockResolvedValueOnce({
        exitCode: 1,
        stdout: '',
        stderr: 'Failed to prepare environment'
      });

      const result = await jumphostService.setupExamEnvironment('test-exam-id', sharedEnvironmentPlan);

      expect(redisClient.persistExamStatus).toHaveBeenNthCalledWith(1, 'test-exam-id', 'PREPARING');
      expect(redisClient.persistExamStatus).toHaveBeenNthCalledWith(2, 'test-exam-id', 'PREPARATION_FAILED');
      expect(MetricService.sendMetrics).toHaveBeenCalledWith('test-exam-id', {
        event: {
          examLabState: 'PREPARATION_FAILED'
        }
      });
      expect(result).toEqual({
        success: false,
        error: 'Failed to prepare exam environment',
        details: {
          host: 'jumphost',
          environmentId: 'shared',
          stdout: '',
          stderr: 'Failed to prepare environment',
          exitCode: 1
        }
      });
    });
  });

  describe('cleanupExamEnvironment', () => {
    it('cleans up the environment and marks the exam completed', async () => {
      sshService.executeCommand.mockResolvedValueOnce({
        exitCode: 0,
        stdout: 'Environment cleaned up successfully',
        stderr: ''
      });

      const result = await jumphostService.cleanupExamEnvironment('test-exam-id', sharedEnvironmentPlan);

      expect(redisClient.persistExamStatus).toHaveBeenNthCalledWith(1, 'test-exam-id', 'CLEANING_UP');
      expect(redisClient.persistExamStatus).toHaveBeenNthCalledWith(2, 'test-exam-id', 'COMPLETED');
      expect(sshService.executeCommand).toHaveBeenCalledWith(
        "cleanup-exam-env 'cluster' 'k8s-api-server'",
        { host: 'jumphost' }
      );
      expect(MetricService.sendMetrics).toHaveBeenCalledWith('test-exam-id', {
        event: {
          cleanupLabState: 'COMPLETED'
        }
      });
      expect(result).toEqual({
        success: true,
        message: 'Exam environment cleaned up successfully',
        details: {
          stdout: 'Environment cleaned up successfully'
        }
      });
    });

    it('marks cleanup as failed when the jumphost command fails', async () => {
      sshService.executeCommand.mockResolvedValueOnce({
        exitCode: 1,
        stdout: '',
        stderr: 'Failed to clean up environment'
      });

      const result = await jumphostService.cleanupExamEnvironment('test-exam-id', sharedEnvironmentPlan);

      expect(redisClient.persistExamStatus).toHaveBeenNthCalledWith(1, 'test-exam-id', 'CLEANING_UP');
      expect(redisClient.persistExamStatus).toHaveBeenNthCalledWith(2, 'test-exam-id', 'CLEANUP_FAILED');
      expect(MetricService.sendMetrics).toHaveBeenCalledWith('test-exam-id', {
        event: {
          cleanupLabState: 'CLEANUP_FAILED'
        }
      });
      expect(result).toEqual({
        success: false,
        error: 'Failed to clean up exam environment',
        details: {
          host: 'jumphost',
          environmentId: 'shared',
          stdout: '',
          stderr: 'Failed to clean up environment',
          exitCode: 1
        }
      });
    });
  });
});
