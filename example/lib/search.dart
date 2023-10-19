import 'package:flutter/material.dart';

class MySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    // Actions for the search bar (e.g., clear query).
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // Leading icon (e.g., back button).
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, "null");
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Build and display search results based on query.
    return Text('Search Results for: $query');
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Display search suggestions as the user types.
    final List<String> suggestions = ['Apple', 'Banana', 'Cherry', 'Date'];
    final filteredSuggestions = query.isEmpty
        ? suggestions
        : suggestions
            .where((suggestion) =>
                suggestion.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(filteredSuggestions[index]),
          onTap: () {
            // When a suggestion is tapped, close the search and return the suggestion.
            close(context, filteredSuggestions[index]);
          },
        );
      },
    );
  }
}
