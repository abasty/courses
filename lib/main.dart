import 'dart:io';
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:window_size/window_size.dart';

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
class ModeleCoursesSingleton {
  List<Rayon> rayons = [];
  List<Produit> produits = [];

  @JsonKey(ignore: true)
  Rayon rayonDivers;
  @JsonKey(ignore: true)
  List<Produit> listeSelect = [];

  ModeleCoursesSingleton._privateConstructor();

  static final ModeleCoursesSingleton _instance =
      ModeleCoursesSingleton._privateConstructor();

  factory ModeleCoursesSingleton() {
    return _instance;
  }

  void produitPlus(Produit p) {
    if (++p.quantite == 1) {
      listeSelect.add(p);
      listeSelect.sort((a, b) => a.rayon.nom.compareTo(b.rayon.nom));
    }
    p.fait = false;
    writeToFile();
  }

  void produitMoins(Produit p) {
    if (p.quantite == 0) return;

    if (--p.quantite == 0) {
      listeSelect.remove(p);
    }
    p.fait = false;
    writeToFile();
  }

  void produitZero(Produit p) {
    if (p.quantite == 0) return;
    p.quantite = 0;
    listeSelect.remove(p);
    p.fait = false;
    writeToFile();
  }

  void produitInverse(Produit p) {
    p.quantite == 0 ? modele.produitPlus(p) : modele.produitZero(p);
  }

  void produitMarque(Produit p, value) {
    p.fait = value;
    writeToFile();
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
    writeToFile();
  }

  void majProduit(Produit p, Produit maj) {
    if (p == null)
      modele.produits.add(maj);
    else {
      p.nom = maj.nom;
      p.rayon = maj.rayon;
    }
    produits.sort((a, b) => a.rayon.nom.compareTo(b.rayon.nom));
    writeToFile();
    print("MAJ modèle faite");
  }

  void fromJson(Map<String, dynamic> json) {
    Produit produitFromElement(dynamic e) {
      if (e == null) return null;
      Produit p = Produit.fromJson(e as Map<String, dynamic>);
      Rayon r = rayons.singleWhere((e) => e.nom == p.rayon.nom);
      p.rayon = r;
      return p;
    }

    rayons = (json['rayonTable'] as List)
        ?.map(
            (e) => e == null ? null : Rayon.fromJson(e as Map<String, dynamic>))
        ?.toList();
    produits =
        (json['produitTable'] as List)?.map(produitFromElement)?.toList();
    rayonDivers = rayons.singleWhere((e) => e.nom == "Divers");
    listeSelect.addAll(produits.where((e) => e.quantite > 0));
  }

  factory ModeleCoursesSingleton.fromJson(Map<String, dynamic> json) =>
      _$DBFromJson(json);
  Map<String, dynamic> toJson() => _$DBToJson(this);

  Future<void> readFromFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + "/courses.json";
    final file = File(path);
    String json;
    if (file.existsSync()) {
      json = file.readAsStringSync();
    } else {
      json = await rootBundle.loadString("assets/courses.json");
    }
    fromJson(jsonDecode(json));
  }

  Future<void> writeToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + "/courses.json";
    final file = File(path);
    file.writeAsStringSync(jsonEncode(toJson()));
    print("Sauvegarde faite");
  }
}

var modele = ModeleCoursesSingleton();

class CoursesApp extends StatefulWidget {
  @override
  CoursesAppState createState() => CoursesAppState();
}

class CoursesAppState extends State<CoursesApp> with TickerProviderStateMixin {
  TabController _tabController;
  var _actionIcon = Icons.add;

  @override
  void initState() {
    super.initState();
    setWindowTitle('Exemple Courses');
    setWindowFrame(Rect.fromLTRB(0, 0, 400, 600));
    modele.readFromFile().then((_) => setState(() {}));
    _tabController = TabController(vsync: this, length: 2)
      ..addListener(
        () {
          setState(
            () {
              _actionIcon = _tabController.index == 0
                  ? Icons.add
                  : Icons.remove_shopping_cart;
            },
          );
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: (context) => _buildScaffold(context)),
    );
  }

  Scaffold _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Produits"),
            Tab(text: "Liste"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabProduits(),
          _buildTabListe(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(_actionIcon),
        onPressed: () {
          if (_tabController.index == 0) {
            _editeProduit(context, null);
          } else {
            setState(() => modele.retireFaits());
          }
        },
      ),
    );
  }

  Widget _buildTabProduits() {
    return ListView.builder(
      itemCount: modele.produits.length,
      itemBuilder: (context, index) {
        Produit p = modele.produits[index];
        return ListTile(
          title: Text(p.nom),
          subtitle: Text(p.rayon.nom),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
          selected: p.quantite > 0,
          onTap: () {
            _itemTap(p);
          },
          onLongPress: () {
            _editeProduit(context, p);
          },
        );
      },
    );
  }

  Widget _buildTabListe() {
    return ListView.builder(
      itemCount: modele.listeSelect.length,
      itemBuilder: (context, index) {
        Produit p = modele.listeSelect[index];
        return CheckboxListTile(
          title: Text("${p.nom} ${p.quantite > 1 ? '(${p.quantite})' : ''}"),
          subtitle: Text(p.rayon.nom),
          value: p.fait,
          onChanged: (bool value) {
            _checkBoxChanged(p, value);
          },
        );
      },
    );
  }

  void _iconMoinsPressed(Produit p) {
    setState(() => modele.produitMoins(p));
  }

  void _iconPlusPressed(Produit p) {
    setState(() => modele.produitPlus(p));
  }

  void _itemTap(Produit p) {
    setState(() => modele.produitInverse(p));
  }

  void _editeProduit(BuildContext context, Produit p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProduitForm(p),
      ),
    );
    setState(() {});
  }

  void _checkBoxChanged(Produit p, bool value) {
    setState(() => modele.produitMarque(p, value));
  }
}

class EditProduitForm extends StatefulWidget {
  final Produit _p;

  EditProduitForm(this._p);

  @override
  EditProduitFormState createState() {
    return EditProduitFormState(_p);
  }
}

class EditProduitFormState extends State<EditProduitForm> {
  final _formKey = GlobalKey<FormState>();
  final Produit _init;
  Produit _maj;

  EditProduitFormState(this._init) {
    _init != null
        ? _maj = Produit(_init.nom, _init.rayon)
        : _maj = Produit("", modele.rayonDivers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.clear), onPressed: _annulePressed),
        title: Text(_init == null ? "Création" : "Édition"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _validePressed,
          ),
        ],
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _buildForm(),
      ),
    );
  }

  void _annulePressed() {
    Navigator.pop(context);
  }

  void _validePressed() {
    if (_formKey.currentState.validate()) {
      modele.majProduit(_init, _maj);
      Navigator.pop(context);
    }
  }

  Widget _buildRayonButtons() {
    return Expanded(
      child: ListView.builder(
        itemCount: modele.rayons.length,
        itemBuilder: (context, index) {
          return RadioListTile<Rayon>(
            title: Text(modele.rayons[index].nom),
            value: modele.rayons[index],
            groupValue: _maj.rayon,
            onChanged: (Rayon r) => setState(() => _maj.rayon = r),
          );
        },
      ),
    );
  }

  Widget _buildProduitNom() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Nom*',
        hintText: 'Nom du produit',
      ),
      initialValue: _maj.nom,
      validator: (nom) {
        if (nom.length < 2) {
          return 'Le nom doit contenir au moins deux caractères';
        } else {
          _maj.nom = nom;
          return null;
        }
      },
    );
  }

  Form _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProduitNom(),
          _buildRayonButtons(),
        ],
      ),
    );
  }
}

void main() {
  runApp(CoursesApp());
}
