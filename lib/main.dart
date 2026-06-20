import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const KucharkaApp());
}

class KucharkaApp extends StatelessWidget {
  const KucharkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuchařka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

// 🍲 MODEL
class Recipe {
  final String name;
  final List<String> ingredients;
  final List<String> steps;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.steps,
  });
}

// 🏠 HOME
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Recipe> recipes = [];

  void addRecipe(Recipe recipe) {
    setState(() => recipes.add(recipe));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje kuchařka')),
      body: recipes.isEmpty
          ? const Center(child: Text('Zatím žádné recepty'))
          : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];

                return ListTile(
                  title: Text(recipe.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailPage(recipe: recipe),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Přidat recept',
        onPressed: () async {
          final recipe = await Navigator.push<Recipe>(
            context,
            MaterialPageRoute(builder: (_) => const AddRecipePage()),
          );

          if (recipe != null) addRecipe(recipe);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ➕ PŘIDÁNÍ RECEPTU
class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final name = TextEditingController();
  final ingredients = TextEditingController();
  final steps = TextEditingController();

  List<String> splitLines(String text) {
    return text
        .split('\n')
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nový recept')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Název'),
            ),
            TextField(
              controller: ingredients,
              decoration: const InputDecoration(
                labelText: 'Ingredience (každá na nový řádek)',
              ),
              maxLines: 4,
            ),
            TextField(
              controller: steps,
              decoration: const InputDecoration(
                labelText: 'Postup (každý krok na nový řádek)',
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  Recipe(
                    name: name.text,
                    ingredients: splitLines(ingredients.text),
                    steps: splitLines(steps.text),
                  ),
                );
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }
}

// 👀 DETAIL RECEPTU
class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Ingredience',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...recipe.ingredients.map((e) => Text('• $e')),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Spustit režim vaření'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CookingModePage(recipe: recipe),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('Postup',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...recipe.steps.map((e) => Text('• $e')),
          ],
        ),
      ),
    );
  }
}

// 🍳 REŽIM VAŘENÍ (NVDA + TTS + klávesnice)
class CookingModePage extends StatefulWidget {
  final Recipe recipe;

  const CookingModePage({super.key, required this.recipe});

  @override
  State<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends State<CookingModePage> {
  int index = 0;
  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    speakStep();
  }

  void speakStep() async {
    final text =
        'Krok ${index + 1} z ${widget.recipe.steps.length}. ${widget.recipe.steps[index]}';

    await tts.setLanguage("cs-CZ");
    await tts.setSpeechRate(0.5);
    await tts.speak(text);
  }

  void next() {
    if (index < widget.recipe.steps.length - 1) {
      setState(() => index++);
      speakStep();
    }
  }

  void back() {
    if (index > 0) {
      setState(() => index--);
      speakStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.recipe.steps[index];

    return Scaffold(
      appBar: AppBar(title: const Text('Režim vaření')),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space) {
              next();
              return KeyEventResult.handled;
            }

            if (event.logicalKey == LogicalKeyboardKey.backspace) {
              back();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Semantics(
          liveRegion: true,
          label:
              'Krok ${index + 1} z ${widget.recipe.steps.length}. $step',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Krok ${index + 1} z ${widget.recipe.steps.length}\n\n$step',
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(onPressed: back, child: const Text('Zpět')),
            ElevatedButton(onPressed: next, child: const Text('Další')),
          ],
        ),
      ),
    );
  }
}