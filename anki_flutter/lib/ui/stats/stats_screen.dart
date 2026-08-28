import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/stats_repository.dart';
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
      appBar: AppBar(title: Text('Статистика — ${widget.title}')),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    Text('ОБЗОР', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Ритм обучения', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Короткая сводка и динамика повторений.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _TodayRow(today: stats.today),
                    const SizedBox(height: AppSpacing.lg),
                    _ChartCard(
                      title: 'Прогноз повторений (30 дней)',
                      child: _ForecastChart(data: stats.forecast),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ChartCard(
                      title: 'История повторений (30 дней)',
                      child: _HistoryChart(data: stats.reviewHistory),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ChartCard(
                      title: 'Карточки по статусу',
                      child: _CardCountsChart(counts: stats.cardCounts),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ChartCard(
                      title: 'Интервалы повторения',
                      child: _BucketChart(buckets: stats.intervalHistogram),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ChartCard(
                      title: 'Коэффициент лёгкости',
                      child: _BucketChart(buckets: stats.easeHistogram),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SummaryRow(stats: stats),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(kAppRadius),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.today});

  final TodayStats today;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveStatRow(
      tiles: [
        _StatTile(label: 'Повторено сегодня', value: '${today.reviewCount}'),
        _StatTile(label: 'Минут', value: '${today.minutesStudied}'),
        _StatTile(label: 'Точность', value: '${today.accuracyPct.round()}%'),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});

  final DeckStats stats;

  @override
  Widget build(BuildContext context) {
    return _ResponsiveStatRow(
      tiles: [
        _StatTile(label: 'Заметок', value: '${stats.totalNotes}'),
        _StatTile(label: 'Всего повторений', value: '${stats.totalReviews}'),
        _StatTile(label: 'Изучено (зрелые)', value: '${stats.matureCount}'),
      ],
    );
  }
}

class _ResponsiveStatRow extends StatelessWidget {
  const _ResponsiveStatRow({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 1 : 3;
        final width = (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final tile in tiles) SizedBox(width: width, child: tile)],
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(kAppRadius),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
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
              reservedSize: 20,
              interval: 5,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${value.round()}д', style: TextStyle(fontSize: 10, color: colors.muted)),
              ),
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
              BarChartRodData(toY: d.count.toDouble(), color: AppColors.accent, width: 5),
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
              reservedSize: 20,
              interval: 5,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${value.round()}д', style: TextStyle(fontSize: 10, color: colors.muted)),
              ),
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
              BarChartRodData(toY: d.count.toDouble(), color: AppColors.good, width: 5),
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
