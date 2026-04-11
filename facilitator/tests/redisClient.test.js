const mockSetEx = jest.fn();
const mockGet = jest.fn();
const mockDel = jest.fn();
const mockOn = jest.fn();
const mockClient = {
  isOpen: true,
  setEx: mockSetEx,
  get: mockGet,
  del: mockDel,
  on: mockOn
};

jest.mock('redis', () => ({
  createClient: jest.fn(() => mockClient)
}));

jest.mock('../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  http: jest.fn(),
  debug: jest.fn()
}));

const redisClient = require('../src/utils/redisClient');

describe('redisClient TTL defaults', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSetEx.mockResolvedValue('OK');
  });

  it('uses a one-hour TTL when persisting exam info', async () => {
    await redisClient.persistExamInfo('exam-1', { name: 'cka-005' });

    expect(mockSetEx).toHaveBeenCalledWith(
      'exam:info:exam-1',
      3600,
      JSON.stringify({ name: 'cka-005' })
    );
  });

  it('uses a one-hour TTL when persisting exam status', async () => {
    await redisClient.persistExamStatus('exam-1', 'READY');

    expect(mockSetEx).toHaveBeenCalledWith('exam:status:exam-1', 3600, 'READY');
  });

  it('uses a one-hour TTL when persisting exam results', async () => {
    await redisClient.persistExamResult('exam-1', { score: 100 });

    expect(mockSetEx).toHaveBeenCalledWith(
      'exam:result:exam-1',
      3600,
      JSON.stringify({ score: 100 })
    );
  });

  it('uses a one-hour TTL when setting the current exam id', async () => {
    await redisClient.setCurrentExamId('exam-1');

    expect(mockSetEx).toHaveBeenCalledWith('current-exam-id', 3600, 'exam-1');
  });
});
