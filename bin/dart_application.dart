import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

Future<int?> login() async {
  print("===== Login =====");
  stdout.write("Username: ");
  String? username = stdin.readLineSync()?.trim();
  stdout.write("Password: ");
  String? password = stdin.readLineSync()?.trim();

  if (username == null ||
      password == null ||
      username.isEmpty ||
      password.isEmpty) {
    print("Incomplete input");
    return null;
  }

  final body = {"username": username, "password": password};
  final url = Uri.parse('http://localhost:3000/login');
  final response = await http.post(url, body: body);

  if (response.statusCode == 200) {
    final result = json.decode(response.body);
    print(result["message"]);
    return result["userId"];
  } else if (response.statusCode == 401 || response.statusCode == 500) {
    print(response.body);
    return null;
  } else {
    print("Unknown error");
    return null;
  }
}

Future<void> allExpenses(int userId) async {
  final url = Uri.parse('http://localhost:3000/expenses/$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResult = json.decode(response.body) as List;
    int total = 0;
    print("-------------All Expenses---------");
    for (var exp in jsonResult) {
      final dt = DateTime.tryParse(exp['date'].toString());
      final dtLocal = dt?.toLocal();
      print(
        "${exp['id']}. ${exp['item']} : ${exp['paid']}฿ @ ${dtLocal ?? exp['date']}",
      );
      total += int.tryParse(exp['paid'].toString()) ?? 0;
    }
    print("Total expenses = $total฿");
  } else {
    print("Failed to fetch all expenses");
  }
}

Future<void> todayExpenses(int userId) async {
  final url = Uri.parse('http://localhost:3000/expenses/$userId/today');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResult = json.decode(response.body) as List;
    int total = 0;
    print("------------Today's Expenses-----------");
    for (var exp in jsonResult) {
      final dt = DateTime.tryParse(exp['date'].toString());
      final dtLocal = dt?.toLocal();
      print(
        "${exp['id']}. ${exp['item']} : ${exp['paid']}฿ @ ${dtLocal ?? exp['date']}",
      );
      total += int.tryParse(exp['paid'].toString()) ?? 0;
    }
    print("Total expenses = $total฿");
  } else {
    print("Failed to fetch today's expenses");
  }
}

Future<void> searchExpenses(int userId) async {
  final url = Uri.parse('http://localhost:3000/expenses/$userId');
  final response = await http.get(url);

  if (response.statusCode != 200) {
    print("Error: ${response.statusCode}");
    return;
  }
  final expenses = jsonDecode(response.body) as List;

  stdout.write("Item to search: ");
  String? search = stdin.readLineSync()?.trim();

  if (search == null || search.isEmpty) {
    print("No item: $search\n");
    return;
  }

  final results = expenses.where((e) {
    final item = (e['item'] ?? '').toString().toLowerCase();
    return item.contains(search.toLowerCase());
  }).toList();

  if (results.isEmpty) {
    print("No item: $search\n");
  } else {
    for (var e in results) {
      final dt = DateTime.parse(e['date']);
      final dtLocal = dt.toLocal();
      print("${e['id']}. ${e['item']} : ${e['paid']}฿ : $dtLocal");
    }
    print("");
  }
}

Future<void> addExpenses(int userId) async {
  final url = Uri.parse('http://localhost:3000/expenses/add/$userId');
  print("===== Add new item =====");
  stdout.write("Item: ");
  String? item = stdin.readLineSync()?.trim();
  stdout.write("Paid: ");
  String? paid = stdin.readLineSync()?.trim();

  if (item == null || item.isEmpty || paid == null || paid.isEmpty) {
    print("Invalid input\n");
    return;
  }

  final paidAmount = int.tryParse(paid);
  if (paidAmount == null) {
    print("Please input a number\n");
    return;
  }

  final body = jsonEncode({
    "user_id": userId,
    "item": item,
    "paid": paidAmount,
  });

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  if (response.statusCode == 201) {
    print("Inserted!\n");
  } else {
    print("Failed to add expense. Error: ${response.statusCode}\n");
  }
}

Future<void> deleteExpenses(int userId) async {
  print("===== Delete an item =====");
  stdout.write("Item id: ");
  String? idInput = stdin.readLineSync()?.trim();

  final expenseId = int.tryParse(idInput ?? '');
  if (expenseId == null) {
    print("Please input a valid number\n");
    return;
  }

  final url = Uri.parse('http://localhost:3000/expenses/delete/$userId/$expenseId');
  final response = await http.delete(url);

  if (response.statusCode == 200) {
    print("Deleted!\n");
  } else if (response.statusCode == 404) {
    print("Expense not found\n");
  } else {
    print("Failed to delete expense");
  }
}

Future<void> menuLoop(int userId) async {
  while (true) {
    print("========= Expense Tracking App ========");
    print("1. All expenses");
    print("2. Today's expenses");
    print("3. Search expense");
    print("4. Add new expense");
    print("5. Delete an expense");
    print("6. Exit");
    stdout.write("Choose... ");
    String? choice = stdin.readLineSync()?.trim();

    switch (choice) {
      case '1':
        await allExpenses(userId);
        break;
      case '2':
        await todayExpenses(userId);
        break;
      case '3':
        await searchExpenses(userId);
        break;
      case '4':
        await addExpenses(userId);
        break;
      case '5':
        await todayExpenses(userId);
        break;
      case '6':
        print("-----Bye--------");
        return;
      default:
        print("Invalid choice, please try again.");
    }
  }
}

Future<void> main() async {
  final userId = await login();
  if (userId != null) {
    await menuLoop(userId);
  }
}
