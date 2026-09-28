export type EventsKpi = {
  totalCount: number;
  pendingCount: number;
  processedCount: number;
  processingCount: number;
  unprocessedCount: number;
  scheduledCount: number;
};

export type AttemptsKpi = {
  totalAttempts: number;
  scheduledCount: number;
  processingCount: number;
  successCount: number;
  retryCount: number;
  failedCount: number;
  discardedCount: number;
  successRate: number | null;
  p95LatencyMs: number | null;
};
