import 'bytes.dart';
import 'history.dart';

enum InsightLevel { info, warning, critical }

/// Something worth a look, shown on the Now and Usage pages.
class Insight {
  const Insight(this.level, this.title, this.detail);
  final InsightLevel level;
  final String title;
  final String detail;
}

/// Days under this are never called unusual, whatever the average.
const _spikeFloor = 200 * 1000 * 1000;
const _uploadFloor = 1000 * 1000 * 1000;

/// What stands out today: plans running out, a day far above the usual,
/// more going out than coming in.
List<Insight> insightsFor({
  required UsageSummary summary,
  required List<PlanStatus> plans,
  double spikeFactor = 3,
}) {
  final out = <Insight>[];
  for (final p in plans) {
    final name = p.plan.name;
    switch (p.state) {
      case PlanState.over:
        out.add(
          Insight(
            InsightLevel.critical,
            '$name is used up',
            '${bytes(p.used)} of ${bytes(p.plan.capBytes)}; it renews in ${p.daysLeft + 1} days.',
          ),
        );
      case PlanState.warning:
        out.add(
          Insight(
            InsightLevel.warning,
            '$name is ${(p.share * 100).round()}% used',
            '${bytes(p.left)} left for ${p.daysLeft + 1} days: about ${bytes(p.dailyBudget)} a day.',
          ),
        );
      case PlanState.onTrackToExceed:
        out.add(
          Insight(
            InsightLevel.warning,
            '$name may run out',
            'At this pace the period ends at ${bytes(p.projected)} of ${bytes(p.plan.capBytes)}. '
                'About ${bytes(p.dailyBudget)} a day keeps it inside.',
          ),
        );
      case PlanState.fine:
        break;
    }
  }
  final today = summary.todayTraffic;
  if (summary.average30 > 0 && today.total > _spikeFloor && today.total > summary.average30 * spikeFactor) {
    out.add(
      Insight(
        InsightLevel.warning,
        'Unusually busy day',
        '${bytes(today.total)} so far, ${(today.total / summary.average30).toStringAsFixed(1)} times '
            'the 30-day average of ${bytes(summary.average30)}.',
      ),
    );
  }
  if (today.tx > _uploadFloor && today.tx > today.rx) {
    out.add(
      Insight(
        InsightLevel.info,
        'More going out than coming in',
        '${bytes(today.tx)} sent and ${bytes(today.rx)} received today. Backups and cloud sync do this; '
            'if you did not expect it, check Connections.',
      ),
    );
  }
  return out;
}
