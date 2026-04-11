jest.mock('uuid', () => ({
  v4: jest.fn(() => 'exam-123')
}));

jest.mock('../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  http: jest.fn(),
  debug: jest.fn()
}));

jest.mock('../src/utils/redisClient', () => ({
  persistExamInfo: jest.fn(),
  persistExamStatus: jest.fn(),
  setCurrentExamId: jest.fn(),
  getExamInfo: jest.fn(),
  getExamStatus: jest.fn(),
  getCurrentExamId: jest.fn(),
  updateExamStatus: jest.fn(),
  deleteCurrentExamId: jest.fn(),
  deleteAllExamData: jest.fn()
}));

jest.mock('../src/services/jumphostService', () => ({
  setupExamEnvironment: jest.fn(),
  cleanupExamEnvironment: jest.fn(),
  evaluateExamOnJumphost: jest.fn()
}));

jest.mock('../src/services/metricService', () => ({
  sendMetrics: jest.fn()
}));

const examService = require('../src/services/examService');
const redisClient = require('../src/utils/redisClient');
const jumphostService = require('../src/services/jumphostService');

describe('examService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('evaluateExam', () => {
    it('does not mark an exam as evaluating when the exam does not exist', async () => {
      redisClient.getExamInfo.mockResolvedValue(null);

      const result = await examService.evaluateExam('missing-exam', {});

      expect(result).toEqual({
        success: false,
        error: 'Failed to start exam evaluation',
        message: 'Exam not found with ID: missing-exam'
      });
      expect(redisClient.updateExamStatus).not.toHaveBeenCalled();
      expect(jumphostService.evaluateExamOnJumphost).not.toHaveBeenCalled();
    });

    it('marks the exam as evaluation failed when asynchronous jumphost evaluation throws', async () => {
      redisClient.getExamInfo.mockResolvedValue({
        assetPath: 'assets/exams/cka/005',
        config: {},
        environmentPlan: {
          environments: [{ id: 'shared', questionIds: ['1'] }]
        }
      });
      redisClient.getExamStatus.mockResolvedValue('READY');
      redisClient.updateExamStatus.mockResolvedValue('OK');
      jumphostService.evaluateExamOnJumphost.mockRejectedValue(new Error('jumphost down'));

      const result = await examService.evaluateExam('exam-123', {});

      expect(result).toEqual({
        success: true,
        data: {
          examId: 'exam-123',
          status: 'EVALUATING',
          message: 'Exam evaluation started'
        }
      });

      await new Promise((resolve) => setImmediate(resolve));

      expect(redisClient.updateExamStatus).toHaveBeenNthCalledWith(1, 'exam-123', 'EVALUATING');
      expect(redisClient.updateExamStatus).toHaveBeenNthCalledWith(2, 'exam-123', 'EVALUATION_FAILED');
      expect(jumphostService.evaluateExamOnJumphost).toHaveBeenCalledTimes(1);
    });
  });

  describe('createExam', () => {
    it('releases the current exam lock when asynchronous preparation fails', async () => {
      redisClient.getCurrentExamId
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce('exam-123');
      jumphostService.setupExamEnvironment.mockResolvedValue({
        success: false,
        error: 'Failed to prepare exam environment'
      });

      const result = await examService.createExam({
        assetPath: 'assets/exams/cka/005'
      });

      expect(result).toEqual({
        success: true,
        data: {
          id: 'exam-123',
          status: 'CREATED',
          message: 'Exam created successfully and environment preparation started'
        }
      });

      await new Promise((resolve) => setImmediate(resolve));

      expect(redisClient.setCurrentExamId).toHaveBeenCalledWith('exam-123');
      expect(redisClient.deleteCurrentExamId).toHaveBeenCalledTimes(1);
    });
  });

  describe('endExam', () => {
    it('keeps the active exam metadata when jumphost cleanup reports a failure', async () => {
      redisClient.getCurrentExamId.mockResolvedValue('exam-123');
      redisClient.getExamInfo.mockResolvedValue({
        environmentPlan: { environments: [{ id: 'shared' }] }
      });
      jumphostService.cleanupExamEnvironment.mockResolvedValue({
        success: false,
        error: 'Failed to clean up exam environment'
      });

      const result = await examService.endExam('exam-123');

      expect(result).toEqual({
        success: false,
        error: 'Failed to end exam',
        message: 'Failed to clean up exam environment'
      });
      expect(redisClient.deleteCurrentExamId).not.toHaveBeenCalled();
      expect(redisClient.deleteAllExamData).not.toHaveBeenCalled();
    });
  });
});
