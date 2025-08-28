import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

int? loggedInUserId;

void main() async {
  bool loggedIn = await login();
  if (!loggedIn) {
    print("Login failed. Exiting.");
    return;
  }

  while (true) {
    print("\n======== Expense Tracking App ========");
    print("1. All expenses");
    print("2. Today's expense");
    print("3. Search expense");
    print("4. Add new expense");
    print("5. Delete an expense");
    print("6. Exit");
    stdout.write("Choose.. ");
    String? choice = stdin.readLineSync()?.trim();

    if (choice == '1') {
      await showExpenses();
    } else if (choice == '2') {
      await showTodayExpenses();
    } else if (choice == '3') {
      stdout.write("Item to search: ");
      String? keyword = stdin.readLineSync()?.trim();
      if (keyword == null || keyword.isEmpty) {
        print("Invalid keyword.");
        continue;
      }
      final results = await searchExpenses(loggedInUserId!, keyword);
      if (results.isEmpty) {
        print("No item containing that searching keyword,");
      } else {
        for (var exp in results) {
          final dt = DateTime.parse(exp['date']);
          final dtLocal = dt.toLocal();
          print(
            "${exp['id']}. ${exp['item']} : ${exp['paid']}฿ : ${dtLocal.toString().substring(0, 19)}",
          );
        }
      }
    } else if (choice == '4') {
      await addExpense();
    } else if (choice == '5') {
      await deleteExpense();
    } else if (choice == '6') {
      print("----- Bye -----");
      break;
    } else {
      print("Invalid choice.");
    }
  }
}

Future<bool> login() async {
  print("====== Login ======");
  stdout.write("Username: ");
  String? username = stdin.readLineSync()?.trim();
  stdout.write("Password: ");
  String? password = stdin.readLineSync()?.trim();
  if (username == null || password == null) {
    print("Incomplete input");
    return false;
  }

  final body = {"username": username, "password": password};
  final url = Uri.parse('http://localhost:3000/login');
  final response = await http.post(url, body: body);
  if (response.statusCode == 200) {
    final result = json.decode(response.body) as Map<String, dynamic>;
    loggedInUserId = result['userId'];
    return true;
  } else {
    print("Error: Status code ${response.statusCode}");
    print("Response body: ${response.body}");
    return false;
  }
}

Future<void> showExpenses() async {
  if (loggedInUserId == null) {
    print("User not logged in.");
    return;
  }
  final url = Uri.parse(
    'http://localhost:3000/expense?user_id=$loggedInUserId',
  );
  final response = await http.get(url);
  if (response.statusCode != 200) {
    print('Failed to fetch expenses: ${response.body}');
    return;
  }
  final jsonResult = json.decode(response.body) as List;

  int total = 0;
  for (var exp in jsonResult) {
    final dt = DateTime.parse(exp['date']);
    final dtLocal = dt.toLocal();
    print(
      "${exp['id']}. ${exp['item']} : ${exp['paid']}฿ : ${dtLocal.toString().substring(0, 19)}",
    );
    total += exp['paid'] as int;
  }
  print("Total expenses = $total฿");
}

Future<void> addExpense() async {
  if (loggedInUserId == null) {
    print("User not logged in.");
    return;
  }
  print("===== Add new item =====");
  stdout.write("Item: ");
  String? item = stdin.readLineSync()?.trim();
  stdout.write("Paid: ");
  String? paidStr = stdin.readLineSync()?.trim();
  int? paid = int.tryParse(paidStr ?? '');
  if (item == null || item.isEmpty || paid == null) {
    print("Invalid input.");
    return;
  }
  final body = {
    "user_id": loggedInUserId.toString(),
    "item": item,
    "paid": paid.toString(),
  };
  final url = Uri.parse('http://localhost:3000/expense');
  final response = await http.post(url, body: body);
  if (response.statusCode == 201) {
    print("Inserted!");
  } else {
    print("Failed to add expense: ${response.body}");
  }
}

Future<void> deleteExpense() async {
  if (loggedInUserId == null) {
    print("User not logged in.");
    return;
  }
  print("===== Delete an item =====");
  stdout.write("Item id: ");
  String? idStr = stdin.readLineSync()?.trim();
  int? id = int.tryParse(idStr ?? '');
  if (id == null) {
    print("Invalid ID.");
    return;
  }
  final url = Uri.parse(
    'http://localhost:3000/expense/$id?user_id=$loggedInUserId',
  );
  final response = await http.delete(url);
  if (response.statusCode == 200) {
    print("Deleted!");
  } else {
    print("Failed to delete expense: ${response.body}");
  }
}