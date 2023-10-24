import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class Category {
  final String name;
  final Color color;

  Category(this.name, this.color);
}

class Tarefa {
  final String titulo;
  final bool Feito;
  final DateTime? datafinal;
  final Category? category;

  Tarefa(this.titulo, this.Feito, this.datafinal, this.category);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Afazeres',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Tarefa> _Tarefas = <Tarefa>[];
  final List<Category> _categories = [
    Category("Pessoal", Colors.blue),
    Category("Trabalho", Colors.green),
    Category("Estudo", const Color.fromARGB(255, 147, 76, 175))
  ];
  final TextEditingController _TarefaController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  Category? _selectedCategory;

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/Tarefas.json');
  }

  @override
  void initState() {
    super.initState();
    _readTarefas();
  }

  Future<void> _readTarefas() async {
    try {
      final file = await _localFile;
      if (file.existsSync()) {
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        final Tarefas = data.map((e) => Tarefa(e['titulo'], e['Feito'], e['datafinal'] != null ? DateTime.parse(e['datafinal']) : null, _categories.firstWhere((category) => category.name == e['category']))).toList();
        setState(() {
          _Tarefas.clear();
          _Tarefas.addAll(Tarefas);
        });
      }
    } catch (e) {
      print('Error reading Tarefas: $e');
    }
  }

  Future<void> _writeTarefas() async {
    try {
      final file = await _localFile;
      final data = _Tarefas.map((Tarefa) => {
            'titulo': Tarefa.titulo,
            'Feito': Tarefa.Feito,
            'datafinal': Tarefa.datafinal?.toIso8601String(),
            'category': Tarefa.category?.name
          }).toList();
      final encodedData = json.encode(data);
      await file.writeAsString(encodedData);
    } catch (e) {
      print('Erro ao fazer Tarefas: $e');
    }
  }

  void _addTarefa() {
    final titulo = _TarefaController.text;
    DateTime? datafinal;

    if (_dateController.text.isNotEmpty) {
      try {
        datafinal = _dateFormat.parse(_dateController.text);
      } catch (e) {
        print('Erro ao analisar data: $e');
      }
    }

    if (titulo.isNotEmpty && _selectedCategory != null) {
      setState(() {
        _Tarefas.add(Tarefa(titulo, false, datafinal, _selectedCategory));
        _TarefaController.clear();
        _dateController.clear();
        _writeTarefas();
      });
    }
  }

  void _toggleTarefa(int index) {
    setState(() {
      _Tarefas[index] = Tarefa(_Tarefas[index].titulo, !_Tarefas[index].Feito, _Tarefas[index].datafinal, _Tarefas[index].category);
      _writeTarefas();
    });
  }

  void _removeTarefa(int index) {
    setState(() {
      _Tarefas.removeAt(index);
      _writeTarefas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Afazeres'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _Tarefas.length,
              itemBuilder: (context, index) {
                final Tarefa = _Tarefas[index];
                return ListTile(
                  title: Text(
                    Tarefa.titulo,
                    style: TextStyle(color: Tarefa.category?.color ?? Colors.black), // Defina a cor do texto com base na categoria
                  ),
                  subtitle: Tarefa.datafinal != null ? Text('Due: ${_dateFormat.format(Tarefa.datafinal!)}') : null,
                  leading: Checkbox(
                    value: Tarefa.Feito,
                    onChanged: (_) => _toggleTarefa(index),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeTarefa(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _TarefaController,
                        decoration: const InputDecoration(labelText: 'Nova Tarefa'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addTarefa,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(labelText: 'Data Final (dd/MM/aaaa)'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButton<Category>(
                        value: _selectedCategory,
                        onChanged: (Category? category) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        items: _categories.map<DropdownMenuItem<Category>>((Category category) {
                          return DropdownMenuItem<Category>(
                            value: category,
                            child: Text(category.name),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
