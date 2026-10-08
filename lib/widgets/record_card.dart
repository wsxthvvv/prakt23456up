import 'package:flutter/material.dart';

class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.onTap,
  });

  final bool selected;
  final ValueChanged<bool?> onSelected;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(value: selected, onChanged: onSelected),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Wrap(spacing: 0, runSpacing: 0, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class CardBoard extends StatelessWidget {
  const CardBoard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width < 600 ? 1 : 2;
    if (columns == 1) {
      return ListView.builder(itemCount: itemCount, itemBuilder: itemBuilder);
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 196,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
