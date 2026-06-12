import '../types/evaluation_context.dart';

enum WindowDirection { past, future }

/// Past when scoring today (or earlier); future when scoring a day after now.
WindowDirection directionFor(EvaluationContext ctx) =>
    ctx.targetDate.isAfter(ctx.now) ? WindowDirection.future : WindowDirection.past;

/// Window of [duration] anchored to the day being scored.
///
/// - Past: [ctx.now - duration, ctx.now]. During backfill, ctx.now is set to
///   end-of-target-day, so this is the target day's trailing window.
/// - Future: [ctx.targetDate, ctx.targetDate + duration]. Matches the
///   user-facing "next 24h" label for the day being forecast.
(DateTime, DateTime) windowFor(EvaluationContext ctx, Duration duration) {
  return switch (directionFor(ctx)) {
    WindowDirection.past => (ctx.now.subtract(duration), ctx.now),
    WindowDirection.future => (ctx.targetDate, ctx.targetDate.add(duration)),
  };
}
