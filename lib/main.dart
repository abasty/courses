import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:localstorage/localstorage.dart';
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

  final _storage = LocalStorage('courses.json');

  ModeleCoursesSingleton._privateConstructor();

  static final ModeleCoursesSingleton _instance =
      ModeleCoursesSingleton._privateConstructor();

  factory ModeleCoursesSingleton() {
    return _instance;
  }

  void ctrlProduitPlus(Produit p) {
    if (++p.quantite == 1) {
      listeSelect.add(p);
      listeSelect.sort((a, b) => a.rayon.nom.compareTo(b.rayon.nom));
    }
    p.fait = false;
    writeToFile();
    if (kDebugMode) print("MAJ modèle faite");
  }

  void ctrlProduitMoins(Produit p) {
    if (p.quantite == 0) return;

    if (--p.quantite == 0) {
      listeSelect.remove(p);
    }
    p.fait = false;
    writeToFile();
  }

  void ctrlProduitRaz(Produit p) {
    if (p.quantite == 0) return;
    p.quantite = 0;
    listeSelect.remove(p);
    p.fait = false;
    writeToFile();
  }

  void ctrlProduitInverse(Produit p) {
    p.quantite == 0 ? modele.ctrlProduitPlus(p) : modele.ctrlProduitRaz(p);
  }

  void ctrlProduitPrend(Produit p, value) {
    p.fait = value;
    writeToFile();
  }

  void ctrlValideChariot() {
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

  void ctrlMajProduit(Produit p, Produit maj) {
    if (p == null)
      modele.produits.add(maj);
    else {
      p.nom = maj.nom;
      p.rayon = maj.rayon;
    }
    produits.sort((a, b) => a.rayon.nom.compareTo(b.rayon.nom));
    writeToFile();
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
    String json;
    await _storage.ready;
    json = await _storage.getItem('modele');
    if (json == null) {
      json = await rootBundle.loadString("assets/courses.json");
    }
    fromJson(jsonDecode(json));
  }

  Future<void> writeToFile() async {
    await _storage.ready;
    await _storage.setItem("modele", jsonEncode(toJson()));
    if (kDebugMode) print("Sauvegarde faite");
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      if (Platform.isLinux) {
        setWindowTitle('Exemple Courses');
        setWindowFrame(Rect.fromLTRB(0, 0, 400, 600));
      }
    }

    modele.readFromFile().then((_) => setState(() {}));
    _tabController = TabController(vsync: this, length: 2)
      ..addListener(
        () => setState(
          () => _tabController.index == 0
              ? _actionIcon = Icons.add
              : _actionIcon = Icons.remove_shopping_cart,
        ),
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
        onPressed: () => _tabController.index == 0
            ? _editeProduit(context, null)
            : setState(() => modele.ctrlValideChariot()),
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
                onPressed: () => setState(() => modele.ctrlProduitMoins(p)),
              ),
              Text("${p.quantite}"),
              IconButton(
                icon: Icon(Icons.add_circle),
                onPressed: () => setState(() => modele.ctrlProduitPlus(p)),
              ),
            ],
          ),
          selected: p.quantite > 0,
          onTap: () => setState(() => modele.ctrlProduitInverse(p)),
          onLongPress: () => _editeProduit(context, p),
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
          onChanged: (bool value) =>
              setState(() => modele.ctrlProduitPrend(p, value)),
        );
      },
    );
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
      body: _buildForm(),
    );
  }

  void _annulePressed() {
    Navigator.pop(context);
  }

  void _validePressed() {
    if (_formKey.currentState.validate()) {
      modele.ctrlMajProduit(_init, _maj);
      Navigator.pop(context);
    }
  }

  Widget _buildRayonButtons() {
    return Expanded(
      child: ListView.builder(
        itemCount: modele.rayons.length,
        itemBuilder: (context, index) {
          return Container(
            height: 32,
            child: RadioListTile<Rayon>(
              title: Text(modele.rayons[index].nom),
              value: modele.rayons[index],
              groupValue: _maj.rayon,
              onChanged: (Rayon r) => setState(() => _maj.rayon = r),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProduitNom() {
    return TextFormField(
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildProduitNom(),
          ),
          _buildRayonButtons(),
        ],
      ),
    );
  }
}

void main() {
  runApp(CoursesApp());
}
