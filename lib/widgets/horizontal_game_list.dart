import 'package:flutter/material.dart';
import '../models/mini_game.dart';
import '../services/storage_service.dart';
import 'game_card.dart';

class HorizontalGameList extends StatelessWidget {
  final List<MiniGameInfo> games;
  final StorageService? storage;

  const HorizontalGameList({
    super.key,
    required this.games,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: games.length,
        itemBuilder: (ctx, i) {
          final game = games[i];
          final best = storage?.arcadeBestScore(game.id) ?? 0;
          return GameCard(
            game: game,
            bestScore: best,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => game.builder()),
              );
            },
          );
        },
      ),
    );
  }
}
