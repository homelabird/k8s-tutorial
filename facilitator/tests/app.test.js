const request = require('supertest');

jest.mock('../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  http: jest.fn()
}));

jest.mock('../src/utils/redisClient', () => ({
  connect: jest.fn().mockResolvedValue(undefined)
}));

jest.mock('../src/services/examService', () => ({
  createExam: jest.fn(),
  getCurrentExam: jest.fn(),
  getExamQuestions: jest.fn(),
  evaluateExam: jest.fn(),
  endExam: jest.fn(),
  getExamResult: jest.fn()
}));

const redisClient = require('../src/utils/redisClient');
const examService = require('../src/services/examService');
const app = require('../src/app');

describe('app', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    redisClient.connect.mockResolvedValue(undefined);
  });

  it('returns API metadata from the root route', async () => {
    const response = await request(app).get('/');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({
      message: 'Facilitator Service API',
      version: '1.0.0'
    });
  });

  it('returns a JSON 404 payload for unknown routes', async () => {
    const response = await request(app).get('/does-not-exist');

    expect(response.status).toBe(404);
    expect(response.body).toEqual({
      error: 'Not Found',
      message: 'The requested resource /does-not-exist was not found'
    });
  });

  it('rejects malformed JSON bodies with a 400 response', async () => {
    const response = await request(app)
      .post('/api/v1/exams/')
      .set('Content-Type', 'application/json')
      .send('{"examId":');

    expect(response.status).toBe(400);
    expect(response.body).toEqual({
      error: 'Bad Request',
      message: 'Request body must be valid JSON'
    });
  });

  it('rejects invalid exam creation payloads before reaching the service', async () => {
    const response = await request(app)
      .post('/api/v1/exams/')
      .send({});

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('must contain at least one of [examId, assetPath]');
    expect(examService.createExam).not.toHaveBeenCalled();
  });

  it('returns 404 when there is no active exam', async () => {
    examService.getCurrentExam.mockResolvedValue({
      success: false,
      error: 'Not Found',
      message: 'No current exam is active'
    });

    const response = await request(app).get('/api/v1/exams/current');

    expect(response.status).toBe(404);
    expect(response.body).toEqual({
      message: 'No current exam is active'
    });
  });

  it('maps active-exam creation conflicts to HTTP 409', async () => {
    examService.createExam.mockResolvedValue({
      success: false,
      error: 'Exam already exists',
      message: 'Only one exam can be active at a time.',
      currentExamId: 'exam-123'
    });

    const response = await request(app)
      .post('/api/v1/exams/')
      .send({ examId: 'cka-005' });

    expect(response.status).toBe(409);
    expect(response.body).toEqual({
      error: 'Exam already exists',
      message: 'Only one exam can be active at a time.',
      currentExamId: 'exam-123'
    });
  });

  it('maps generic creation failures to HTTP 500', async () => {
    examService.createExam.mockResolvedValue({
      success: false,
      error: 'Failed to create exam',
      message: 'labs index missing'
    });

    const response = await request(app)
      .post('/api/v1/exams/')
      .send({ examId: 'cka-005' });

    expect(response.status).toBe(500);
    expect(response.body).toEqual({
      error: 'Failed to create exam',
      message: 'labs index missing'
    });
  });

  it('serves assessments from both the legacy and canonical routes', async () => {
    const legacyResponse = await request(app).get('/api/v1/assements/');
    const canonicalResponse = await request(app).get('/api/v1/assessments/');

    expect(legacyResponse.status).toBe(200);
    expect(canonicalResponse.status).toBe(200);
    expect(Array.isArray(legacyResponse.body)).toBe(true);
    expect(canonicalResponse.body).toEqual(legacyResponse.body);
  });

  it('includes the promoted CKA 2026 single-domain drills in the assessment listing', async () => {
    const response = await request(app).get('/api/v1/assessments/');

    expect(response.status).toBe(200);

    const ids = response.body.map((lab) => lab.id);
    expect(ids).toEqual(expect.arrayContaining(['cka-006', 'cka-007', 'cka-008', 'cka-009', 'cka-010', 'cka-011', 'cka-012', 'cka-013', 'cka-014', 'cka-015', 'cka-016', 'cka-017', 'cka-018', 'cka-019', 'cka-020', 'cka-021']));

    expect(response.body.find((lab) => lab.id === 'cka-021')).toMatchObject({
      id: 'cka-021',
      assetPath: 'assets/exams/cka/021',
      category: 'CKA',
      examDurationInMinutes: 20
    });
  });

  it('returns the raw exam result payload from the result endpoint', async () => {
    examService.getExamResult.mockResolvedValue({
      success: true,
      data: {
        examId: 'exam-123',
        score: 100
      }
    });

    const response = await request(app).get('/api/v1/exams/exam-123/result');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({
      examId: 'exam-123',
      score: 100
    });
  });

  it('starts the HTTP server after initializing Redis', async () => {
    const server = await app.startServer(0);

    expect(redisClient.connect).toHaveBeenCalledTimes(1);

    await new Promise((resolve, reject) => {
      server.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });
  });

  it('fails server startup when Redis initialization fails', async () => {
    redisClient.connect.mockRejectedValueOnce(new Error('redis unavailable'));

    await expect(app.startServer(0)).rejects.toThrow('redis unavailable');
  });
});
