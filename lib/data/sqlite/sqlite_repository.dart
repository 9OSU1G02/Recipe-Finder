import 'dart:async';
import '../repository.dart';
import 'database_helper.dart';
import '../models/models.dart';

// 2
class SqliteRepository extends Repository {
  // 3
  final dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Recipe>> findAllRecipes() {
    return dbHelper.findAllRecipes();
  }

  @override
  Stream<List<Recipe>> watchAllRecipes() {
    return dbHelper.watchAllRecipes();
  }

  @override
  Stream<List<Ingredient>> watchAllIngredients() {
    return dbHelper.watchAllIngredients();
  }

  @override
  Future<Recipe> findRecipeById(int id) {
    return dbHelper.findRecipeById(id);
  }

  @override
  Future<List<Ingredient>> findAllIngredients() {
    return dbHelper.findAllIngredients();
  }

  @override
  Future<List<Ingredient>> findRecipeIngredients(int recipeId) {
    return dbHelper.findRecipeIngredients(recipeId);
  }

  @override
  Future<int> insertRecipe(Recipe recipe) {
    // 1
    return Future(() async {
      // 2
      final id = await dbHelper.insertRecipe(recipe);
      // 3
      recipe.id = id;
      if (recipe.ingredients != null) {
        for (var ingredient in recipe.ingredients!) {
          // 4
          ingredient.recipeId = id;
        }
        // 5
        insertIngredients(recipe.ingredients!);
      }
      // 6
      return id;
    });
  }

  @override
  Future<List<int>> insertIngredients(List<Ingredient> ingredients) {
    return Future(() async {
      if (ingredients.isNotEmpty) {
        // 1
        final ingredientIds = <int>[];
        // 2
        await Future.forEach(ingredients, (Ingredient ingredient) async {
          // 3
          final futureId = await dbHelper.insertIngredient(ingredient);
          ingredient.id = futureId;
          // 4
          ingredientIds.add(futureId);
        });
        // 5
        return Future.value(ingredientIds);
      } else {
        return Future.value(<int>[]);
      }
    });
  }

  @override
  Future<void> deleteRecipe(Recipe recipe) {
    // 1
    dbHelper.deleteRecipe(recipe);
    // 2
    if (recipe.id != null) {
      deleteRecipeIngredients(recipe.id!);
    }
    return Future.value();
  }

  @override
  Future<void> deleteIngredient(Ingredient ingredient) {
    // 3
    dbHelper.deleteIngredient(ingredient);
    return Future.value();
  }

  @override
  Future<void> deleteIngredients(List<Ingredient> ingredients) {
    // 4
    dbHelper.deleteIngredients(ingredients);
    return Future.value();
  }

  @override
  Future<void> deleteRecipeIngredients(int recipeId) {
    // 5
    dbHelper.deleteRecipeIngredients(recipeId);
    return Future.value();
  }
  @override
  void close() {
    dbHelper.close();
  }

  @override
  Future init() async {
    await dbHelper.database;
    return Future.value();
  }
}
