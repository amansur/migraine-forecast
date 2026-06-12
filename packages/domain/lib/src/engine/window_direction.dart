import '../types/evaluation_context.dart';

enum WindowDirection { past, future }

/// Past when scoring today (or earlier); future when scoring a day after now.
WindowDirection directionFor(EvaluationContext ctx) =>
    ctx.targetDate.isAfter(ctx.now) ? WindowDirection.future : WindowDirection.past;
