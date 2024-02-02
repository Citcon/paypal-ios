import SwiftUI
import PaymentButtons
import PayPalWebPayments

struct PayPalWebButtonsView: View {

    @ObservedObject var payPalWebViewModel: PayPalWebViewModel

    @State private var selectedFundingSource: PayPalWebCheckoutFundingSource = .paypal

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 16) {
                HStack {
                    Text("Checkout with PayPal")
                        .font(.system(size: 20))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
                Picker("Funding Source", selection: $selectedFundingSource) {
                    Text("PayPal").tag(PayPalWebCheckoutFundingSource.paypal)
                    Text("PayPal Credit").tag(PayPalWebCheckoutFundingSource.paypalCredit)
                    Text("Pay Later").tag(PayPalWebCheckoutFundingSource.paylater)
                }
                .pickerStyle(SegmentedPickerStyle())

                switch selectedFundingSource {
                case .paypalCredit:
                    PayPalCreditButtonView(color: .gold, edges: .softEdges, size: .standard) {
                        payPalWebViewModel.paymentButtonTapped(funding: .paylater)
                    }
                case .paylater:
                    PayPalPayLaterButtonView(color: .gold, edges: .softEdges, size: .standard) {
                        payPalWebViewModel.paymentButtonTapped(funding: .paylater)
                    }
                case .paypal:
                    PayPalButtonView(color: .gold, size: .standard) {
                        payPalWebViewModel.paymentButtonTapped(funding: .paypal)
                    }
                }
            }
            .frame(height: 150)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.gray, lineWidth: 2)
                    .padding(5)
            )
        }
    }
}
