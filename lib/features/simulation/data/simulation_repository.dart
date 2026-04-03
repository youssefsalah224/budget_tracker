import '../domain/simulation_result.dart';

abstract interface class SimulationRepository {
  Future<SimulationResult> fetchSimulation();
}
