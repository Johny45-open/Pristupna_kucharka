import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const KucharkaApp());
}

class KucharkaApp extends StatefulWidget {
  const KucharkaApp({super.key});

  @override
  State<KucharkaApp> createState() => _KucharkaAppState();
}

class _KucharkaAppState extends State<KucharkaApp> {
  ThemeMode themeMode = ThemeMode.system;

  void setTheme(ThemeMode mode) {
    setState(() => themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuchařka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: HomePage(onThemeChange: setTheme),
    );
  }
}

class Recipe {
  String name;
  List<String> ingredients;
  List<String> steps;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.steps,
  });
}

/// 🔊 TTS MANAGER (QUEUE – žádné překryvy)
class TtsManager {
  final FlutterTts tts = FlutterTts();
  final List<String> _queue = [];
  bool _isSpeaking = false;

  Future<void> init() async {
    await tts.setSpeechRate(0.5);

    try {
      await tts.setLanguage("cs-CZ");
    } catch (_) {
      await tts.setLanguage("en-US");
    }

    tts.setCompletionHandler(() {
      _isSpeaking = false;
      _playNext();
    });

    tts.setCancelHandler(() {
      _isSpeaking = false;
      _playNext();
    });
  }

  void speak(String text) {
    _queue.add(text);
    _playNext();
  }

  Future<void> _playNext() async {
    if (_isSpeaking) return;
    if (_queue.isEmpty) return;

    _isSpeaking = true;
    final text = _queue.removeAt(0);

    await tts.stop();
    await tts.speak(text);
  }

  void clear() {
    _queue.clear();
    tts.stop();
  }
}

class HomePage extends StatefulWidget {
  final void Function(ThemeMode) onThemeChange;

  const HomePage({super.key, required this.onThemeChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Recipe> recipes = [];

  void addRecipe(Recipe recipe) {
    setState(() => recipes.add(recipe));
  }

  void openSettings() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motiv'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Světlý'),
              onTap: () {
                widget.onThemeChange(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Tmavý'),
              onTap: () {
                widget.onThemeChange(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Systémový'),
              onTap: () {
                widget.onThemeChange(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje kuchařka'),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: openSettings,
          )
        ],
      ),
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
        onPressed: () async {
          final recipe = await Navigator.push<Recipe>(
            context,
            MaterialPageRoute(
              builder: (_) => const AddRecipePage(),
            ),
          );

          if (recipe != null) addRecipe(recipe);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final name = TextEditingController();
  final ingredients = TextEditingController();
  final steps = TextEditingController();
  
  late TtsManager _ttsManager;

  @override
  void initState() {
    super.initState();
    _ttsManager = TtsManager();
    _ttsManager.init(); // Inicializace TTS pro případné hlášky na této obrazovce
  }

  @override
  void dispose() {
    name.dispose();
    ingredients.dispose();
    steps.dispose();
    _ttsManager.clear(); // Vyčištění TTS při opuštění formuláře
    super.dispose();
  }

  List<String> split(String text) =>
      text.split('\n').where((e) => e.trim().isNotEmpty).toList();

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
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Ingredience'),
            ),
            TextField(
              controller: steps,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Postup (1 krok na řádek)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (steps.text.trim().isEmpty) {
                  // Aplikace chybu vizuálně zobrazí...
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recept musí mít aspoň jeden krok'),
                    ),
                  );
                  
                  // ...a nevidomému uživateli ji hned nahlas přečte!
                  _ttsManager.speak("Chyba. Recept musí mít aspoň jeden krok");
                  return;
                }

                Navigator.pop(
                  context,
                  Recipe(
                    name: name.text,
                    ingredients: split(ingredients.text),
                    steps: split(steps.text),
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

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingredience',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...recipe.ingredients.map((e) => Text('• $e')),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Spustit vaření'),
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
            const Text(
              'Postup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...recipe.steps.map((e) => Text('• $e')),
          ],
        ),
      ),
    );
  }
}

class CookingModePage extends StatefulWidget {
  final Recipe recipe;

  const CookingModePage({super.key, required this.recipe});

  @override
  State<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends State<CookingModePage> {
  int index = 0;
  late TtsManager ttsManager;

  @override
  void initState() {
    super.initState();

    ttsManager = TtsManager();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ttsManager.init();

      // Zde už kontrola prázdnosti teoreticky nemusí být, protože do CookingModePage 
      // už uživatele nepustí detail receptu, potažmo nepůjde takový recept ani uložit.
      // Pro jistotu zde necháváme bezpečné opuštění bez prodlevy.
      if (widget.recipe.steps.isEmpty) {
        Navigator.pop(context);
        return;
      }

      ttsManager.speak("Režim vaření spuštěn");
      ttsManager.speak(stepText());
    });
  }

  @override
  void dispose() {
    ttsManager.clear();
    super.dispose();
  }

  String stepText() {
    final step = widget.recipe.steps[index];
    return "Krok ${index + 1} z ${widget.recipe.steps.length}. $step";
  }

  void next() {
    if (index < widget.recipe.steps.length - 1) {
      setState(() => index++);
      ttsManager.speak(stepText());
    }
  }

  void back() {
    if (index > 0) {
      setState(() => index--);
      ttsManager.speak(stepText());
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.recipe.steps.isNotEmpty
        ? widget.recipe.steps[index]
        : "Žádné kroky";

    return Scaffold(
      appBar: AppBar(title: const Text('Režim vaření')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            widget.recipe.steps.isNotEmpty
                ? 'Krok ${index + 1} z ${widget.recipe.steps.length}\n\n$step'
                : 'Recept nemá žádné kroky',
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
      bottomNavigationBar: widget.recipe.steps.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed: back, child: const Text('Zpět')),
                  ElevatedButton(
                      onPressed: next, child: const Text('Další')),
                ],
              ),
            )
          : null,
    );
  }
}