import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/stats_repository.dart';
import '../common/ios.dart';
import '../theme/app_theme.dart';

/// Anki-style statistics: today's summary, due forecast, review history,
/// card-status breakdown, and interval/ease distributions. Pass [deckId] for
/// a single deck's stats, or omit it for the whole collection.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, this.deckId, required this.title});

  final int? deckId;
  final String title;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DeckStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await context.read<StatsRepository>().load(deckId: widget.deckId);
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: Text(widget.deckId == null ? 'Статистика' : widget.title)),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    const SectionHeader('Сегодня'),
                    _TodayRow(today: stats.today),
                    const SectionHeader('Прогноз на 30 дней'),
                    _ChartCard(
                      subtitle: 'Сколько карточек придёт на повторение',
                      empty: stats.forecast.every((d) => d.count == 0),
                      child: _ForecastChart(data: stats.forecast),
                    ),
                    const SectionHeader('История за 30 дней'),
                    _ChartCard(
                      subtitle: 'Сколько карточек вы повторили',
                      empty: stats.reviewHistory.every((d) => d.count == 0),
                      child: _HistoryChart(data: stats.reviewHistory),
                    ),
                    const SectionHeader('Карточки по статусу'),
                    _ChartCard(child: _CardCountsChart(counts: stats.cardCounts)),
                    const SectionHeader('Интервалы повторения'),
                    _ChartCard(child: _BucketChart(buckets: stats.intervalHistogram)),
                    const SectionHeader('Коэффициент лёгкости'),
                    _ChartCard(child: _BucketChart(buckets: stats.easeHistogram)),
                    const SectionHeader('Всего'),
                    _SummaryRow(stats: stats),
                  ],
                ),
              ),
            ),
    );
  }
}

/// A white block in the same inset style as the grouped lists elsewhere, so
/// the section caption above it and its contents share one left edge.
class _ChartCard extends StatelessWidget {
  const _ChartCard({this.subtitle, this.empty = false, required this.child});

  final String? subtitle;

  /// No data yet: show a short note instead of a tall, blank chart.
  final bool empty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm + 4),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (subtitle != null) ...[
              Text(subtitle!, style: TextStyle(fontSize: 14, color: colors.muted)),
              const SizedBox(height: AppSpacing.md),
            ],
            if (empty)
              SizedBox(
                height: 60,
                child: Center(child: Text('Пока нет данных', style: TextStyle(fontSize: 14, color: colors.muted))),
              )
            else
              SizedBox(height: 150, child: child),
          ],
        ),
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.today});

  final TodayStats today;

  @override
  Widget build(BuildContext context) {
    return _StatRow(
      tiles: [
        _StatTile(label: 'Повторено', value: '${today.reviewCount}'),
        _StatTile(label: 'Минут', value: '${today.minutesStudied}'),
        _StatTile(label: 'Точность', value: today.reviewCount == 0 ? '—' : '${today.accuracyPct.round()}%'),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});

  final DeckStats stats;

  @override
  Widget build(BuildContext context) {
    return _StatRow(
      tiles: [
        _StatTile(label: 'Заметок', value: '${stats.totalNotes}'),
        _StatTile(label: 'Повторений', value: '${stats.totalReviews}'),
        _StatTile(label: 'Выучено', value: '${stats.matureCount}'),
      ],
    );
  }
}

/// Three equal tiles side by side, inset like the rest of the screen.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm + 4, AppSpacing.sm, AppSpacing.sm + 4),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: colors.text),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: colors.muted)),
        ],
      ),
    );
  }
}

/// X-axis label for the 30-day charts: one tick per week ("сегодня",
/// "+7 д" / "−7 д"), kept inside the chart so edge labels don't clip.
/// Labelling every day crammed 30 labels into one line on a phone.
Widget _weekTick(double value, TitleMeta meta, Color color, {required bool future}) {
  final day = value.round();
  if (day % 7 != 0) return const SizedBox.shrink();
  final text = day == 0 ? 'сегодня' : (future ? '+$day д' : '−${-day} д');
  return SideTitleWidget(
    meta: meta,
    space: 6,
    fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
    child: Text(text, style: TextStyle(fontSize: 11, color: color)),
  );
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.data});

  final List<DayCount> data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxY = data.map((d) => d.count).fold<int>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) => _weekTick(value, meta, colors.muted, future: true),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.surface,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem('${rod.toY.round()}', TextStyle(color: colors.text)),
          ),
        ),
        barGroups: [
          for (final d in data)
            BarChartGroupData(x: d.dayOffset, barRods: [
              BarChartRodData(
                toY: d.count.toDouble(),
                color: AppColors.accent,
                width: 5,
                borderRadius: BorderRadius.circular(2),
              ),
            ]),
        ],
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.data});

  final List<DayCount> data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxY = data.map((d) => d.count).fold<int>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) => _weekTick(value, meta, colors.muted, future: false),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.surface,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem('${rod.toY.round()}', TextStyle(color: colors.text)),
          ),
        ),
        barGroups: [
          for (final d in data)
            BarChartGroupData(x: d.dayOffset, barRods: [
              BarChartRodData(
                toY: d.count.toDouble(),
                color: AppColors.good,
                width: 5,
                borderRadius: BorderRadius.circular(2),
              ),
            ]),
        ],
      ),
    );
  }
}

class _BucketChart extends StatelessWidget {
  const _BucketChart({required this.buckets});

  final List<BucketCount> buckets;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (buckets.every((b) => b.count == 0)) {
      return Center(child: Text('Нет данных', style: TextStyle(color: colors.muted)));
    }
    final maxY = buckets.map((b) => b.count).fold<int>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(buckets[i].label, style: TextStyle(fontSize: 9, color: colors.muted)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.surface,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem('${rod.toY.round()}', TextStyle(color: colors.text)),
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: buckets[i].count.toDouble(), color: AppColors.accent, width: 14),
            ]),
        ],
      ),
    );
  }
}

class _CardCountsChart extends StatelessWidget {
  const _CardCountsChart({required this.counts});

  final CardCounts counts;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (counts.total == 0) {
      return Center(child: Text('Нет карточек', style: TextStyle(color: colors.muted)));
    }
    final entries = [
      (label: 'Новые', value: counts.newCount, color: AppColors.accent),
      (label: 'Изучение', value: counts.learningCount, color: AppColors.again),
      (label: 'Повторение', value: counts.reviewCount, color: AppColors.good),
      (label: 'Отложены', value: counts.suspendedCount, color: colors.muted),
    ];
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: [
                for (final e in entries)
                  if (e.value > 0)
                    PieChartSectionData(
                      value: e.value.toDouble(),
                      color: e.color,
                      title: '${e.value}',
                      radius: 40,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in entries) _LegendRow(label: e.label, value: e.value, color: e.color),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text('$value', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
