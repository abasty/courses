import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'main.g.dart';

@JsonSerializable()
class Rayon {
  String nom;

  Rayon(this.nom);

  factory Rayon.fromJson(Map<String, dynamic> json) => _$RayonFromJson(json);
  Map<String, dynamic> toJson() => _$RayonToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Produit {
  String nom;
  Rayon rayon;
  int quantite = 0;
  bool fait = false;

  Produit(this.nom, this.rayon);
  factory Produit.fromJson(Map<String, dynamic> json) =>
      _$ProduitFromJson(json);
  Map<String, dynamic> toJson() => _$ProduitToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DB {
  List<Rayon> rayonTable = [];
  List<Produit> produitTable = [];

  @JsonKey(ignore: true)
  Rayon rayonDivers;
  @JsonKey(ignore: true)
  List<Produit> listeSelect = [];

  DB();

  void produitPlus(Produit p) {
    if (++p.quantite == 1) {
      listeSelect.add(p);
      listeSelect.sort((a, b) => a.rayon.nom.compareTo(b.rayon.nom));
    }
    p.fait = false;
  }

  void produitMoins(Produit p) {
    if (p.quantite == 0) return;

    if (--p.quantite == 0) {
      listeSelect.remove(p);
    }
    p.fait = false;
  }

  void produitZero(Produit p) {
    if (p.quantite == 0) return;
    p.quantite = 0;
    listeSelect.remove(p);
    p.fait = false;
  }

  void retireFaits() {
    listeSelect.removeWhere((p) {
      bool fait = p.fait;
      if (fait) {
        p.quantite = 0;
        p.fait = false;
      }
      return fait;
    });
  }

  static DB _$DBFromJson(Map<String, dynamic> json) {
    var db = DB();

    Produit produitFromElement(dynamic e) {
      if (e == null) return null;
      Produit p = Produit.fromJson(e as Map<String, dynamic>);
      Rayon r = db.rayonTable.singleWhere((e) => e.nom == p.rayon.nom);
      p.rayon = r;
      return p;
    }

    db
      ..rayonTable = (json['rayonTable'] as List)
          ?.map((e) =>
              e == null ? null : Rayon.fromJson(e as Map<String, dynamic>))
          ?.toList()
      ..produitTable =
          (json['produitTable'] as List)?.map(produitFromElement)?.toList()
      ..rayonDivers = db.rayonTable.singleWhere((e) => e.nom == "Divers")
      ..listeSelect.addAll(db.produitTable.where((e) => e.quantite > 0));
    return db;
  }

  factory DB.fromJson(Map<String, dynamic> json) => _$DBFromJson(json);
  Map<String, dynamic> toJson() => _$DBToJson(this);

  static Future<String> readDBFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + "/courses.json";
    final file = File(path);
    return await file.readAsString();
  }

  Future<int> readDB() async {
    try {
      final file = await _localFile;

      // Read the file
      String contents = await file.readAsString();

      return int.parse(contents);
    } catch (e) {
      // If encountering an error, return 0
      return 0;
    }
  }

  Future<File> writeDB() async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString('$DB');
  }
}

void main() {
  runApp(CoursesApp());
}

class CoursesApp extends StatefulWidget {
  @override
  CoursesAppState createState() => CoursesAppState();
}

class CoursesAppState extends State<CoursesApp> with TickerProviderStateMixin {
  TabController tabController;
  var actionIcon = Icons.add;
  DB db = DB.fromJson(jsonDecode(
      '{"rayonTable":[{"nom":"Divers"},{"nom":"Boucherie"},{"nom":"Légumes"},{"nom":"Fruits"},{"nom":"Epicerie"},{"nom":"Frais"},{"nom":"Fromagerie"},{"nom":"Poissonerie"},{"nom":"Surgelés"},{"nom":"Boulangerie"},{"nom":"Hygiène"},{"nom":"Boisson"}],"produitTable":[{"nom":"Escalope de porc","rayon":{"nom":"Boucherie"},"quantite":0,"fait":false},{"nom":"Gîte de boeuf","rayon":{"nom":"Boucherie"},"quantite":1,"fait":false},{"nom":"Paleron de boeuf","rayon":{"nom":"Boucherie"},"quantite":0,"fait":false},{"nom":"Pomme de terre","rayon":{"nom":"Légumes"},"quantite":0,"fait":false},{"nom":"Carotte","rayon":{"nom":"Légumes"},"quantite":4,"fait":false},{"nom":"Poireau","rayon":{"nom":"Légumes"},"quantite":0,"fait":false},{"nom":"Sel","rayon":{"nom":"Epicerie"},"quantite":0,"fait":false},{"nom":"Poivre","rayon":{"nom":"Epicerie"},"quantite":0,"fait":false},{"nom":"Huile","rayon":{"nom":"Epicerie"},"quantite":1,"fait":false}]}'));

  @override
  void initState() {
    super.initState();
    // read db from file
    DB.readDBFile().then((value) => print(value));
    tabController = TabController(vsync: this, length: 2)
      ..addListener(() {
        setState(() {
          actionIcon =
              tabController.index == 0 ? Icons.add : Icons.remove_shopping_cart;
        });
      });
  }

  Widget _buildTabProduits(BuildContext context) {
    return ListView.builder(
        itemCount: db.produitTable.length,
        itemBuilder: (context, index) {
          Produit p = db.produitTable[index];
          return ListTile(
              title: Text(p.nom),
              subtitle: Text(p.rayon.nom),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(Icons.remove_circle),
                  onPressed: () {
                    _iconMoinsPressed(p);
                  },
                ),
                Text(p.quantite.toString()),
                IconButton(
                  icon: Icon(Icons.add_circle),
                  onPressed: () {
                    _iconPlusPressed(p);
                  },
                ),
              ]),
              selected: p.quantite > 0,
              onTap: () {
                _itemTap(p);
              },
              onLongPress: () {
                _editeProduit(context, p.nom);
              });
        });
  }

  void _iconMoinsPressed(Produit p) {
    setState(() => db.produitMoins(p));
    db.writeDBFile();
  }

  void _iconPlusPressed(Produit p) {
    setState(() => db.produitPlus(p));
    db.writeDBFile();
  }

  void _itemTap(Produit p) {
    setState(() => p.quantite == 0 ? db.produitPlus(p) : db.produitZero(p));
    db.writeDBFile();
  }

  Widget _buildTabListe() {
    return ListView.builder(
      itemCount: db.listeSelect.length,
      itemBuilder: (context, index) {
        Produit p = db.listeSelect[index];
        return CheckboxListTile(
          title: Text("${p.nom} ${p.quantite > 1 ? '(${p.quantite})' : ''}"),
          subtitle: Text(p.rayon.nom),
          value: p.fait,
          onChanged: (bool value) {
            _checkBoxPressed(p, value);
          },
        );
      },
    );
  }

  void _checkBoxPressed(Produit p, bool value) {
    setState(() => p.fait = value);
    db.writeDBFile();
  }

  void _editeProduit(BuildContext context, String nom) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProduitForm(nom, db),
        ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Courses'),
                  bottom: TabBar(
                    controller: tabController,
                    tabs: [
                      Tab(text: "Produits"),
                      Tab(text: "Liste"),
                    ],
                  ),
                ),
                body: TabBarView(controller: tabController, children: [
                  _buildTabProduits(context),
                  _buildTabListe(),
                ]),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
                floatingActionButton: FloatingActionButton(
                  child: Icon(actionIcon),
                  onPressed: () {
                    if (tabController.index == 0) {
                      _editeProduit(context, "");
                    } else {
                      setState(() => db.retireFaits());
                      db.writeDBFile();
                    }
                  },
                ),
              )),
    );
  }
}

class ProduitForm extends StatefulWidget {
  final String nom;
  final DB db;

  ProduitForm(this.nom, this.db);

  @override
  ProduitFormState createState() {
    return ProduitFormState(nom, db);
  }
}

class ProduitFormState extends State<ProduitForm> {
  final _formKey = GlobalKey<FormState>();
  final DB db;

  Produit _produit;
  Rayon _rayon;
  bool _new;

  Widget _buildRayonButtons() {
    return Expanded(
        child: ListView.builder(
      itemCount: db.rayonTable.length,
      itemBuilder: (context, index) {
        return RadioListTile<Rayon>(
          title: Text(db.rayonTable[index].nom),
          value: db.rayonTable[index],
          groupValue: _rayon,
          onChanged: (Rayon value) {
            setState(() {
              _rayon = value;
            });
          },
        );
      },
    ));
  }

  Widget _buildProduitNom() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Nom*',
        hintText: 'Nom du produit',
      ),
      initialValue: _produit.nom,
      validator: (value) {
        if (value.length < 2) {
          return 'Le nom doit contenir au moins deux caractères';
        } else {
          _produit.nom = value;
          return null;
        }
      },
    );
  }

  ProduitFormState(String nom, this.db) {
    _produit =
        db.produitTable.firstWhere((p) => p.nom == nom, orElse: () => null);
    _new = _produit == null;
    if (_new) _produit = Produit("", db.rayonDivers);
    _rayon = _produit.rayon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.clear), onPressed: () => Navigator.pop(context)),
          title: Text(_new ? "Création" : "Edition"),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  if (_new) db.produitTable.add(_produit);
                  _produit.rayon = _rayon;
                  db.writeDBFile();
                  Navigator.pop(context);
                }
              },
            ),
          ],
          backgroundColor: Colors.deepPurple,
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Builder(
              builder: (context) => Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProduitNom(),
                        _buildRayonButtons(),
                      ]))),
        ));
  }
}
