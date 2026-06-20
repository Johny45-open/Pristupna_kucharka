import 'package:flutter/material.dart';

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
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Recipe {
  final String name;
  final String ingredients;
  final String instructions;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.instructions,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Recipe> recipes = [];

  void addRecipe(Recipe recipe) {
    setState(() {
      recipes.add(recipe);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje kuchařka'),
      ),
      body: recipes.isEmpty
          ? const Center(
              child: Text('Zatím nemáš žádné recepty'),
            )
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

          if (recipe != null) {
            addRecipe(recipe);
          }
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
  final nameController = TextEditingController();
  final ingredientsController = TextEditingController();
  final instructionsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nový recept'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Název receptu',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Ingredience',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: instructionsController,
              decoration: const InputDecoration(
                labelText: 'Postup',
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  Recipe(
                    name: nameController.text,
                    ingredients: ingredientsController.text,
                    instructions: instructionsController.text,
                  ),
                );
              },
              child: const Text('Uložit recept'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Ingredience',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(recipe.ingredients),
            const SizedBox(height: 20),
            const Text(
              'Postup',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(recipe.instructions),
          ],
        ),
      ),
    );
  }
}