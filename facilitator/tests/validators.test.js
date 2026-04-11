const {
  validateExecuteCommand,
  validateCreateExam,
  validateEvaluateExam,
  validateExamEvents
} = require('../src/middleware/validators');

jest.mock('../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  http: jest.fn()
}));

function createResponse() {
  return {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis()
  };
}

describe('validators', () => {
  let next;

  beforeEach(() => {
    next = jest.fn();
  });

  describe('validateExecuteCommand', () => {
    it('rejects requests without a command', () => {
      const req = { body: {} };
      const res = createResponse();

      validateExecuteCommand(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(next).not.toHaveBeenCalled();
    });

    it('accepts requests with a command', () => {
      const req = { body: { command: 'kubectl get ns' } };
      const res = createResponse();

      validateExecuteCommand(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('validateCreateExam', () => {
    it('rejects requests without examId or assetPath', () => {
      const req = { body: {} };
      const res = createResponse();

      validateCreateExam(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: expect.stringContaining('must contain at least one of [examId, assetPath]')
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('accepts requests with an examId', () => {
      const req = { body: { examId: 'ckad-003' } };
      const res = createResponse();

      validateCreateExam(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
    });

    it('accepts requests with an assetPath', () => {
      const req = { body: { assetPath: 'assets/exams/ckad/003' } };
      const res = createResponse();

      validateCreateExam(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
    });
  });

  describe('validateEvaluateExam', () => {
    it('rejects non-object request bodies', () => {
      const req = { body: [] };
      const res = createResponse();

      validateEvaluateExam(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: expect.stringContaining('must be of type object')
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('accepts object request bodies', () => {
      const req = { body: {} };
      const res = createResponse();

      validateEvaluateExam(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
    });
  });

  describe('validateExamEvents', () => {
    it('rejects requests without an events object', () => {
      const req = { body: { events: 'bad' } };
      const res = createResponse();

      validateExamEvents(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Bad Request',
        message: 'Request body must include events field as an object'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('rejects requests with an events array', () => {
      const req = { body: { events: ['bad'] } };
      const res = createResponse();

      validateExamEvents(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: 'Bad Request',
        message: 'Request body must include events field as an object'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('accepts requests with an events object', () => {
      const req = { body: { events: { tabSwitchCount: 1 } } };
      const res = createResponse();

      validateExamEvents(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
    });
  });
});
