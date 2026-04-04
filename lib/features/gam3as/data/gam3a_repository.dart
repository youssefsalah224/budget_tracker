import '../domain/gam3a.dart';

abstract interface class Gam3aRepository {
  Future<List<Gam3a>> fetchAll();
  Future<Gam3a> create(Gam3a gam3a);
  Future<Gam3a> update(Gam3a gam3a);
  Future<void> delete(int id);
}
