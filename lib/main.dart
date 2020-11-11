import 'package:flutter/material.dart';

class Rayon {
  String nom;

  Rayon(this.nom);
}

class Produit {
  String nom;
  Rayon rayon;
  int quantite = 0;
  bool fait = false;

  Produit(this.nom, this.rayon);
}

class DB {
  Rayon rayonDivers;
  List<Rayon> rayonTable = [];
  List<Produit> produitTable = [];
  List<Produit> listeSelect = [];

  DB() {
    rayonDivers = Rayon("Divers");
    rayonTable.add(rayonDivers);
    Rayon r = Rayon("Boucherie");
    rayonTable.add(r);
    produitTable.addAll([
      Produit("Escalope de porc", r),
      Produit("Gîte de boeuf", r),
      Produit("Paleron de boeuf", r),
    ]);
    r = Rayon("Légumes");
    rayonTable.add(r);
    rayonTable.add(Rayon("Fruits"));
    produitTable.addAll([
      Produit("Pomme de terre", r),
      Produit("Carotte", r),
      Produit("Poireau", r),
    ]);
    r = Rayon("Epicerie");
    rayonTable.add(r);
    produitTable.addAll([
      Produit("Sel", r),
      Produit("Poivre", r),
      Produit("Huile", r),
    ]);
    rayonTable.add(Rayon("Frais"));
    rayonTable.add(Rayon("Fromagerie"));
    rayonTable.add(Rayon("Poissonerie"));
    rayonTable.add(Rayon("Surgelés"));
    rayonTable.add(Rayon("Boulangerie"));
    rayonTable.add(Rayon("Hygiène"));
    rayonTable.add(Rayon("Boisson"));
  }

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
  DB db = DB();

  @override
  void initState() {
    super.initState();
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
                    setState(() => db.produitMoins(p));
                  },
                ),
                Text(p.quantite.toString()),
                IconButton(
                  icon: Icon(Icons.add_circle),
                  onPressed: () {
                    setState(() => db.produitPlus(p));
                  },
                ),
              ]),
              selected: p.quantite > 0,
              onTap: () {
                setState(() =>
                    p.quantite == 0 ? db.produitPlus(p) : db.produitZero(p));
              },
              onLongPress: () {
                _editeProduit(context, p.nom);
              });
        });
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
            setState(() => p.fait = value);
          },
        );
      },
    );
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
                floatingActionButton: FloatingActionButton(
                  child: Icon(actionIcon),
                  onPressed: () {
                    if (tabController.index == 0) {
                      _editeProduit(context, "");
                    } else {
                      setState(() => db.retireFaits());
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
