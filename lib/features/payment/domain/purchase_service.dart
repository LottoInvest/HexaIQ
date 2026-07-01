import '../../hexaiq/domain/hexaiq_repository.dart';
import '../../../app/release_config.dart';
import 'purchase_status.dart';

abstract class PurchaseService {
  const PurchaseService();

  Future<PurchaseStatus> loadStatus();

  Future<PurchaseStatus> purchaseProfessional();

  Future<PurchaseStatus> restorePurchases() => loadStatus();
}

class RepositoryPurchaseService extends PurchaseService {
  const RepositoryPurchaseService(this.repository);

  final HexaIQRepository repository;

  @override
  Future<PurchaseStatus> loadStatus() {
    return repository.loadPurchaseStatus();
  }

  @override
  Future<PurchaseStatus> purchaseProfessional() async {
    await repository.savePurchaseStatus(PurchaseStatus.professionalPurchased);
    return PurchaseStatus.professionalPurchased;
  }
}

class ProfessionalUnlockConfig {
  const ProfessionalUnlockConfig({
    this.productId = ReleaseConfig.professionalProductId,
    this.priceLabel = ReleaseConfig.professionalPriceLabel,
  });

  final String productId;
  final String priceLabel;
}
