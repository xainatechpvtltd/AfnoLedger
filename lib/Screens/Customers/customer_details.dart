import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/transactions_provider.dart';
import 'package:mobile_pos/Screens/Customers/edit_customer.dart';
import 'package:mobile_pos/Screens/Customers/sms_sent_confirmation.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/core/theme/_app_colors.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/widgets/empty_widget/_empty_widget.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../GlobalComponents/check_subscription.dart';
import '../../GlobalComponents/glonal_popup.dart';
import '../../GlobalComponents/sales_transaction_widget.dart';
import '../../PDF Invoice/pdf_common_functions.dart';
import '../../PDF Invoice/purchase_invoice_pdf.dart';
import '../../Provider/profile_provider.dart';
import '../../currency.dart';
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../invoice_details/purchase_invoice_details.dart';
import '../invoice_details/sales_invoice_details_screen.dart';
import 'Model/parties_model.dart';
import 'Repo/parties_repo.dart';

// ignore: must_be_immutable
class CustomerDetails extends StatefulWidget {
  CustomerDetails({super.key, required this.party});
  Party party;

  @override
  State<CustomerDetails> createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> showDeleteConfirmationAlert({
    required BuildContext context,
    required String id,
    required WidgetRef ref,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context1) {
        return AlertDialog(
          title: Text(
            lang.S.of(context).confirmPassword,
            //'Confirm Delete'
          ),
          content: Text(
            lang.S.of(context).areYouSureYouWant,
            //'Are you sure you want to delete this party?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                lang.S.of(context).cancel,
                //'Cancel'
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final party = PartyRepository();
                await party.deleteParty(id: id, context: context, ref: ref);
              },
              child: Text(lang.S.of(context).delete,
                  // 'Delete',
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, cRef, __) {
      final providerData = cRef.watch(salesTransactionProvider);
      final purchaseList = cRef.watch(purchaseTransactionProvider);
      final printerData = cRef.watch(thermalPrinterProvider);
      final businessInfo = cRef.watch(businessInfoProvider);
      final businessData = cRef.watch(businessSettingProvider);
      final _theme = Theme.of(context);
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            surfaceTintColor: kWhite,
            backgroundColor: Colors.white,
            title: Text(
              widget.party.type != 'Supplier' ? lang.S.of(context).CustomerDetails : lang.S.of(context).supplierDetails,
            ),
            actions: [
              businessInfo.when(data: (details) {
                return Row(
                  children: [
                    IconButton(
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        EditCustomer(customerModel: widget.party).launch(context);
                      },
                      icon: const Icon(
                        FeatherIcons.edit2,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          await showDeleteConfirmationAlert(context: context, id: widget.party.id.toString(), ref: cRef);
                        },
                        icon: const Icon(
                          FeatherIcons.trash2,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                );
              }, error: (e, stack) {
                return Text(e.toString());
              }, loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              })
            ],
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0.0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          widget.party.image == null
                              ? Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(20),
                                    color: _theme.colorScheme.primary,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (widget.party.name != null && widget.party.name!.length >= 2)
                                          ? widget.party.name!.substring(0, 2)
                                          : (widget.party.name != null ? widget.party.name! : ''),
                                      style: _theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                                    image: widget.party.image == null
                                        ? const DecorationImage(
                                            image: AssetImage('images/no_shop_image.png'),
                                            fit: BoxFit.cover,
                                          )
                                        : DecorationImage(
                                            image: NetworkImage('${APIConfig.domain}${widget.party.image!}'),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                          const SizedBox(height: 20),
                          Text(
                            widget.party.name ?? 'n/a',
                            style: _theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.party.phone ?? 'n/a',
                            style: _theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ContactOptionsRow(party: widget.party),
                          const SizedBox(height: 19),
                        ],
                      ),
                      Text(
                        lang.S.of(context).recentTransaction,
                        style: _theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                widget.party.type != 'Supplier'
                    ? providerData.when(data: (transaction) {
                        final filteredTransactions = transaction.where((t) => t.party?.id == widget.party.id).toList();
                        return filteredTransactions.isNotEmpty
                            ? ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredTransactions.length,
                                itemBuilder: (context, index) {
                                  final currentTransaction = filteredTransactions[index];
                                  return salesTransactionWidget(
                                    context: context,
                                    ref: cRef,
                                    businessInfo: businessInfo.value!,
                                    sale: currentTransaction,
                                    advancePermission: false,
                                    showProductQTY: true,
                                  );
                                },
                              )
                            : EmptyWidget(
                                message: TextSpan(text: lang.S.of(context).noTransaction),
                              );
                      }, error: (e, stack) {
                        return Text(e.toString());
                      }, loading: () {
                        return const Center(child: CircularProgressIndicator());
                      })
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: purchaseList.when(data: (pTransaction) {
                          final filteredTransactions = pTransaction.where((t) => t.party?.id == widget.party.id).toList();

                          return filteredTransactions.isNotEmpty
                              ? ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredTransactions.length,
                                  itemBuilder: (context, index) {
                                    final currentTransaction = filteredTransactions[index];
                                    return GestureDetector(
                                      onTap: () {
                                        PurchaseInvoiceDetails(
                                          transitionModel: currentTransaction,
                                          businessInfo: businessInfo.value!,
                                        ).launch(context);
                                      },
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: context.width(),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      "${lang.S.of(context).totalProduct} : ${currentTransaction.details!.length.toString()}",
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                    Text('#${currentTransaction.invoiceNumber}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: currentTransaction.dueAmount! <= 0
                                                            ? const Color(0xff0dbf7d).withValues(alpha: 0.1)
                                                            : const Color(0xFFED1A3B).withValues(alpha: 0.1),
                                                        borderRadius: const BorderRadius.all(Radius.circular(2)),
                                                      ),
                                                      child: Text(
                                                        currentTransaction.dueAmount! <= 0 ? lang.S.of(context).paid : lang.S.of(context).unPaid,
                                                        style: TextStyle(
                                                          color: currentTransaction.dueAmount! <= 0 ? const Color(0xff0dbf7d) : const Color(0xFFED1A3B),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(currentTransaction.purchaseDate!.substring(0, 10),
                                                        style: _theme.textTheme.bodyMedium?.copyWith(color: DAppColors.kSecondary)),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  '${lang.S.of(context).total} : $currency${currentTransaction.totalAmount.toString()}',
                                                  style: _theme.textTheme.bodyMedium?.copyWith(color: DAppColors.kSecondary),
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${lang.S.of(context).due}: $currency${currentTransaction.dueAmount.toString()}',
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
                                                    businessInfo.when(data: (data) {
                                                      return Row(
                                                        children: [
                                                          IconButton(
                                                            onPressed: () async {
                                                              PrintPurchaseTransactionModel model = PrintPurchaseTransactionModel(
                                                                purchaseTransitionModel: currentTransaction,
                                                                personalInformationModel: data,
                                                              );

                                                              await printerData.printPurchaseThermalInvoiceNow(
                                                                transaction: model,
                                                                productList: model.purchaseTransitionModel!.details,
                                                                context: context,
                                                              );
                                                            },
                                                            icon: const Icon(
                                                              FeatherIcons.printer,
                                                              color: Colors.grey,
                                                            ),
                                                            visualDensity: const VisualDensity(
                                                              horizontal: -4,
                                                              vertical: -4,
                                                            ),
                                                            style: IconButton.styleFrom(
                                                              padding: EdgeInsets.zero,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          businessData.when(data: (business) {
                                                            return IconButton(
                                                              style: IconButton.styleFrom(
                                                                  padding: EdgeInsets.zero,
                                                                  visualDensity: const VisualDensity(
                                                                    horizontal: -4,
                                                                    vertical: -4,
                                                                  )),
                                                              onPressed: () => PurchaseInvoicePDF.generatePurchaseDocument(currentTransaction, data, context, business),
                                                              icon: const Icon(
                                                                Icons.picture_as_pdf,
                                                                color: Colors.grey,
                                                              ),
                                                            );
                                                          }, error: (e, stack) {
                                                            return Text(e.toString());
                                                          }, loading: () {
                                                            return const Center(
                                                              child: CircularProgressIndicator(),
                                                            );
                                                          }),
                                                        ],
                                                      );
                                                    }, error: (e, stack) {
                                                      return Text(e.toString());
                                                    }, loading: () {
                                                      return Text(lang.S.of(context).loading);
                                                    }),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(
                                            height: 15,
                                            color: kBorderColor,
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : EmptyWidget(
                                  message: TextSpan(text: lang.S.of(context).noTransaction),
                                );
                        }, error: (e, stack) {
                          return Text(e.toString());
                        }, loading: () {
                          return const Center(child: CircularProgressIndicator());
                        }),
                      ),
              ],
            ),
          ),
          // bottomNavigationBar: ButtonGlobal(
          //   iconWidget: null,
          //   buttontext: lang.S.of(context).viewAll,
          //   iconColor: Colors.white,
          //   buttonDecoration: kButtonDecoration.copyWith(color: kMainColor),
          //   onPressed: () {
          //     Navigator.push(context, MaterialPageRoute(builder: (context)=>const CustomerAllTransactionScreen()));
          //   },
          // ),
        ),
      );
    });
  }
}

// Contact Row
class ContactOptionsRow extends StatefulWidget {
  final Party party;

  const ContactOptionsRow({super.key, required this.party});

  @override
  State<ContactOptionsRow> createState() => _ContactOptionsRowState();
}

class _ContactOptionsRowState extends State<ContactOptionsRow> {
  int selectedIndex = -1;

  void _onButtonTap(int index) async {
    setState(() {
      selectedIndex = index;
    });

    if (index == 0) {
      if (widget.party.phone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number is not available.')),
        );
        return;
      }
      final Uri url = Uri.parse('tel:${widget.party.phone}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else if (index == 1) {
      if (widget.party.type != 'Supplier') {
        showDialog(
          context: context,
          builder: (context1) {
            return SmsConfirmationPopup(
              customerName: widget.party.name ?? '',
              phoneNumber: widget.party.phone ?? '',
              onCancel: () {
                Navigator.pop(context1);
              },
              onSendSms: () async {
                EasyLoading.show(status: 'SMS Sending..');
                PartyRepository repo = PartyRepository();
                await repo.sendCustomerUdeSms(id: widget.party.id!, context: context);
              },
            );
          },
        );
      } else {
        if (widget.party.phone == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number is not available.')),
          );
          return;
        }
        final Uri url = Uri.parse('sms:${widget.party.phone}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      }
    } else if (index == 2) {
      if (widget.party.email == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(widget.party.email!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email address.')),
        );
        return;
      }
      final Uri url = Uri.parse('mailto:${widget.party.email}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  Widget _buildContactButton(int index, IconData icon, String label) {
    final _theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => _onButtonTap(index),
        child: Container(
          padding: const EdgeInsets.all(8),
          height: 90,
          decoration: BoxDecoration(
            color: selectedIndex == index ? kMainColor : kMainColor.withValues(alpha: 0.10),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selectedIndex == index ? kWhite : Colors.black,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: _theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: selectedIndex == index ? kWhite : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildContactButton(0, FeatherIcons.phone, 'Call'),
        const SizedBox(width: 18),
        _buildContactButton(1, FeatherIcons.messageSquare, 'Message'),
        const SizedBox(width: 18),
        _buildContactButton(2, FeatherIcons.mail, 'Email'),
      ],
    );
  }
}
