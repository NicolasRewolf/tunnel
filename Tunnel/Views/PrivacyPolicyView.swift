import SwiftUI

/// In-app privacy policy screen. Apple requires a privacy policy to be
/// "easily accessible" inside the app (Guideline 5.1.1).
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    policyParagraph(
                        title: "Données collectées",
                        body: "Aucune. Tunnel fonctionne entièrement hors-ligne et ne collecte aucune donnée personnelle."
                    )

                    policyParagraph(
                        title: "Données stockées localement",
                        body: "Les informations du contact que tu configures (nom, sous-titre, numéro, photo) sont stockées uniquement sur cet iPhone. Elles ne sont jamais envoyées sur Internet."
                    )

                    policyParagraph(
                        title: "Permissions",
                        body: "Tunnel demande uniquement l'accès à ta photothèque si tu choisis d'ajouter une photo au contact fictif. L'app n'accède pas à tes contacts, à ta localisation, à ton micro, ni à tes appels."
                    )

                    policyParagraph(
                        title: "Partage avec des tiers",
                        body: "Aucun. Tunnel n'intègre aucun service d'analyse, aucun réseau publicitaire, aucun SDK tiers."
                    )

                    policyParagraph(
                        title: "Suppression des données",
                        body: "Désinstalle l'app pour supprimer toutes les données. Aucune sauvegarde externe n'est conservée."
                    )

                    policyParagraph(
                        title: "Contact",
                        body: "Pour toute question, utilise l'e-mail de contact indiqué sur la fiche App Store de Tunnel."
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Confidentialité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }

    private func policyParagraph(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))

            Text(body)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
