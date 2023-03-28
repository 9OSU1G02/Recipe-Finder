import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlbrite/sqlbrite.dart';
import 'package:synchronized/synchronized.dart';
import '../models/models.dart';

class DatabaseHelper {
  static const _databaseName = 'MyDatabase.db';
  static const _databaseVersion = 1;

  static const recipeTable = 'Recipe';
  static const ingredientTable = 'Ingredient';
  static const recipeId = 'recipeId';
  static const ingredientId = 'ingredientId';

  static late BriteDatabase _streamDatabase;
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static var lock = Lock();
  static Database? _database;

  Future _onCreate(Database db, int version) async {
    // 2
    await db.execute('''
        CREATE TABLE $recipeTable (
          $recipeId INTEGER PRIMARY KEY,
          label TEXT,
          image TEXT,
          url TEXT,
          calories REAL,
          totalWeight REAL,
          totalTime REAL
        )
        ''');
    // 3
    await db.execute('''
        CREATE TABLE $ingredientTable (
          $ingredientId INTEGER PRIMARY KEY,
          $recipeId INTEGER,
          name TEXT,
          weight REAL
        )
        ''');
  }

  Future<Database> _initDatabase() async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentDirectory.path, _databaseName);
    Sqflite.setDebugModeOn(true);
    return openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await lock.synchronized(() async {
      if (_database == null) {
        _database = await _initDatabase();
        _streamDatabase = BriteDatabase(_database!);
      }
    });
    return _database!;
  }

  Future<BriteDatabase> get streamDatabase async {
    await database;
    return _streamDatabase;
  }

  List<Recipe> parseRecipes(List<Map<String, dynamic>> recipeList) {
    final recipes = <Recipe>[];
    // 1
    for (final recipeMap in recipeList) {
      // 2
      final recipe = Recipe.fromJson(recipeMap);
      // 3
      recipes.add(recipe);
    }
    // 4
    return recipes;
  }

  List<Ingredient> parseIngredients(List<Map<String, dynamic>> ingredientList) {
    final ingredients = <Ingredient>[];
    for (final ingredientMap in ingredientList) {
      // 5
      final ingredient = Ingredient.fromJson(ingredientMap);
      ingredients.add(ingredient);
    }
    return ingredients;
  }

  Stream<List<Recipe>> watchAllRecipes() async* {
    final db = await instance.streamDatabase;
    yield* db.createQuery(recipeTable).mapToList((row) {
      return Recipe.fromJson(row);
    });
  }

  Stream<List<Ingredient>> watchAllIngredients() async* {
    final db = await instance.streamDatabase;
    yield* db.createQuery(ingredientTable).mapToList((row) {
      return Ingredient.fromJson(row);
    });
  }
  Future<List<Recipe>> findAllRecipes() async {
    final db = await instance.streamDatabase;
    final ingredientList = await db.query(recipeTable);
    final ingredients = parseRecipes(ingredientList);
    return ingredients;
  }

  Future<Recipe> findRecipeById(int id) async {
    final db = await instance.streamDatabase;
    final recipeList = await db.query(
      recipeTable,
      where: 'id = $id',
    );
    final recipes = parseRecipes(recipeList);
    return recipes.first;
  }

  Future<List<Ingredient>> findAllIngredients() async {
    final db = await instance.streamDatabase;
    final ingredientList = await db.query(ingredientTable);
    final ingredients = parseIngredients(ingredientList);
    return ingredients;
  }

  Future<List<Ingredient>> findRecipeIngredients(int recipeId) async {
    final db = await instance.streamDatabase;
    final ingredientList = await db.query(
      ingredientTable,
      where: 'recipeId = $recipeId',
    );
    final ingredients = parseIngredients(ingredientList);
    return ingredients;
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await instance.streamDatabase;
    // 2
    return db.insert(
      table,
      row,
    );
  }

  Future<int> insertRecipe(Recipe recipe) {
    // 3
    return insert(
      recipeTable,
      recipe.toJson(),
    );
  }

  Future<int> insertIngredient(Ingredient ingredient) {
    // 4
    return insert(
      ingredientTable,
      ingredient.toJson(),
    );
  }

  Future<int> _delete(String table, String columnId, int id) async {
    final db = await instance.streamDatabase;
    // 2
    return db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRecipe(Recipe recipe) async {
    // 3
    if (recipe.id != null) {
      return _delete(
        recipeTable,
        recipeId,
        recipe.id!,
      );
    } else {
      return Future.value(-1);
    }
  }

  Future<int> deleteIngredient(Ingredient ingredient) async {
    if (ingredient.id != null) {
      return _delete(
        ingredientTable,
        ingredientId,
        ingredient.id!,
      );
    } else {
      return Future.value(-1);
    }
  }

  Future<void> deleteIngredients(List<Ingredient> ingredients) {
    // 4
    for (final ingredient in ingredients) {
      if (ingredient.id != null) {
        _delete(
          ingredientTable,
          ingredientId,
          ingredient.id!,
        );
      }
    }
    return Future.value();
  }

  Future<int> deleteRecipeIngredients(int id) async {
    final db = await instance.streamDatabase;
    // 5
    return db.delete(
      ingredientTable,
      where: '$recipeId = ?',
      whereArgs: [id],
    );
  }

  void close() {
    _streamDatabase.close();
  }
}
