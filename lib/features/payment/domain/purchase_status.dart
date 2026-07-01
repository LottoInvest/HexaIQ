enum PurchaseStatus { free, professionalPurchased }

extension PurchaseStatusInfo on PurchaseStatus {
  bool get hasProfessionalAccess =>
      this == PurchaseStatus.professionalPurchased;
}
