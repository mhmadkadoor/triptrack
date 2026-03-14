import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_service.dart';

class AiSuggestionsSheet extends ConsumerStatefulWidget {
  final List<String> currentExpenses;

  const AiSuggestionsSheet({super.key, required this.currentExpenses});

  @override
  ConsumerState<AiSuggestionsSheet> createState() => _AiSuggestionsSheetState();
}

class _AiSuggestionsSheetState extends ConsumerState<AiSuggestionsSheet> {
  late Future<List<String>> _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = ref
        .read(aiServiceProvider)
        .getSuggestions(widget.currentExpenses);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.purple.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'AI Suggestions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<String>>(
            future: _suggestionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading suggestions: ${snapshot.error}'),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No suggestions found.'));
              }

              final suggestions = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      title: Text(
                        suggestions[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
