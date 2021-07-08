@JS("window")
library ethereum;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:meta/meta.dart';

import './utils.dart';
import '../../objects.dart';

part 'interop.dart';

@internal
_EthereumImpl? get defaultProviderImpl =>
    hasProperty(_window, 'ethereum') || hasProperty(_window, 'BinanceChain')
        ? _ethereum != null
            ? _ethereum
            : _binanceChain
        : null;

/// Getter for default Ethereum object, cycles through available injector in environment.
Ethereum? get ethereum => Ethereum.provider;

/// Getter for boolean to detect Ethereum object support. without calling itself to prevent js undefined error.
bool get isEthereumSupported => Ethereum.isSupported;

@JS("BinanceChain")
external _EthereumImpl? get _binanceChain;

@JS("ethereum")
external _EthereumImpl? get _ethereum;

@deprecated
@JS("web3")
external _EthereumImpl? get _web3;

@JS("window")
external Object get _window;

@internal
_EthereumImpl getEthereumImpl(Ethereum ethereum) => ethereum._impl;

/// A Dart Ethereum Provider API for consistency across clients and applications.
class Ethereum implements _EthereumImpl {
  /// Ethereeum provider api used in Binance Chain Wallet.
  static Ethereum get binanceChain => Ethereum._internal(_binanceChain!);

  /// Modern Ethereum provider api, injected by many famous environment such as `MetaMask` or `TrustWallet`.
  static Ethereum get ethereum => Ethereum._internal(_ethereum!);

  /// Getter for boolean to detect Ethereum object support. without calling itself to prevent js undefined error.
  static bool get isSupported =>
      hasProperty(_window, 'ethereum') || hasProperty(_window, 'BinanceChain');

  /// Getter for default Ethereum provider object, cycles through available injector in environment.
  static Ethereum? get provider => isSupported
      ? _ethereum != null
          ? Ethereum._internal(_ethereum!)
          : Ethereum._internal(_binanceChain!)
      : null;

  /// Old web3 object, deprecated now.
  @deprecated
  static Ethereum? get web3 =>
      _web3 != null ? Ethereum._internal(_web3!) : null;

  final _EthereumImpl _impl;

  const Ethereum._internal(this._impl);

  @override
  set autoRefreshOnNetworkChange(bool b) =>
      _impl.autoRefreshOnNetworkChange = b;

  /// Returns a hexadecimal string representing the current chain ID.
  ///
  /// Deprecated, Consider using [getChainId] instead.
  @deprecated
  @override
  String get chainId => _impl.chainId;

  /// Returns first [getAccounts] item but may return unexpected value.
  ///
  /// Deprecated, Consider using [getAccounts] instead.
  @deprecated
  @override
  String? get selectedAddress => _impl.selectedAddress;

  /// Returns List of accounts the node controls.
  Future<List<String>> getAccounts() async =>
      (await request<List<dynamic>>('eth_accounts'))
          .map((e) => e.toString())
          .toList();

  /// Returns chain id in [int]
  Future<int> getChainId() async =>
      int.parse((await request('eth_chainId')).toString());

  /// Returns `true` if the provider is connected to the current chain, and `false` otherwise.
  ///
  /// Note that this method has nothing to do with the user's accounts.
  ///
  /// You may often encounter the word `connected` in reference to whether a web3 site can access the user's accounts. In the provider interface, however, `connected` and `disconnected` refer to whether the provider can make RPC requests to the current chain.
  @override
  bool isConnected() => _impl.isConnected();

  /// Returns the number of listeners for the [eventName] events. If no [eventName] is provided, the total number of listeners is returned.
  @override
  int listenerCount([String? eventName]) => _impl.listenerCount(eventName);

  /// Returns the list of Listeners for the [eventName] events.
  @override
  List listeners(String eventName) => _impl.listeners(eventName);

  /// Remove a [listener] for the [eventName] event. If no [listener] is provided, all listeners for [eventName] are removed.
  off(String eventName, [Function? listener]) => callMethod(_impl, 'off',
      listener != null ? [eventName, allowInterop(listener)] : [eventName]);

  /// Add a [listener] to be triggered for each [eventName] event.
  on(String eventName, Function listener) =>
      callMethod(_impl, 'on', [eventName, allowInterop(listener)]);

  /// Add a [listener] to be triggered for each accountsChanged event.
  onAccountsChanged(void Function(List<String> accounts) listener) => on(
      'accountsChanged',
      (List<dynamic> accs) => listener(accs.map((e) => e.toString()).toList()));

  /// Add a [listener] to be triggered for only the next [eventName] event, at which time it will be removed.
  once(String eventName, Function listener) =>
      callMethod(_impl, 'once', [eventName, allowInterop(listener)]);

  /// Add a [listener] to be triggered for each chainChanged event.
  onChainChanged(void Function(int chainId) listener) =>
      on('chainChanged', (dynamic cId) => listener(int.parse(cId.toString())));

  /// Add a [listener] to be triggered for each connect event.
  ///
  /// This event is emitted when it first becomes able to submit RPC requests to a chain.
  ///
  /// We recommend using a connect event handler and the [Ethereum.isConnected] method in order to determine when/if the provider is connected.
  onConnect(void Function(ConnectInfo connectInfo) listener) =>
      on('connect', listener);

  /// Add a [listener] to be triggered for each disconnect event.
  ///
  /// This event is emitted if it becomes unable to submit RPC requests to any chain. In general, this will only happen due to network connectivity issues or some unforeseen error.
  ///
  /// Once disconnect has been emitted, the provider will not accept any new requests until the connection to the chain has been re-restablished, which requires reloading the page. You can also use the [Ethereum.isConnected] method to determine if the provider is disconnected.
  onDisconnect(void Function(ProviderRpcError error) listeners) =>
      on('disconnect', (ProviderRpcError error) => listeners(error));

  /// Add a [listener] to be triggered for each message event [type].
  ///
  /// The MetaMask provider emits this event when it receives some message that the consumer should be notified of. The kind of message is identified by the type string.
  ///
  /// RPC subscription updates are a common use case for the message event. For example, if you create a subscription using `eth_subscribe`, each subscription update will be emitted as a message event with a type of `eth_subscription`.
  onMessage(void Function(String type, dynamic data) listener) => on(
      'message',
      (ProviderMessage message) =>
          listener(message.type, convertToDart(message.data)));

  /// Remove all the listeners for the [eventName] events. If no [eventName] is provided, all events are removed.
  @override
  removeAllListeners([String? eventName]) =>
      _impl.removeAllListeners(eventName);

  /// Use request to submit RPC requests with [method] and optionally [params] to Ethereum via MetaMask or provider that is currently using.
  ///
  /// Returns a Future of generic type that resolves to the result of the RPC method call.
  Future<T> request<T>(String method, [dynamic params]) =>
      promiseToFuture<T>(callMethod(_impl, 'request', [
        params != null
            ? _RequestArgumentsImpl(method: method, params: params)
            : _RequestArgumentsImpl(method: method)
      ]));

  /// Request/Enable the accounts from the current environment.
  ///
  /// Returns List of accounts the node controls.
  ///
  /// This method will only work if you’re using the injected provider from a application like Metamask, Status or TrustWallet.
  ///
  /// It doesn’t work if you’re connected to a node with a default Web3.js provider (WebsocketProvider, HttpProvidder and IpcProvider).
  Future<List<String>> requestAccount() async =>
      (await request<List<dynamic>>('eth_requestAccounts')).cast<String>();

  @override
  String toString() => isSupported
      ? isConnected() && selectedAddress != null
          ? 'connected to chain ${int.tryParse(chainId)} with $selectedAddress'
          : 'not connected to chain ${int.tryParse(chainId)}'
      : 'provider not supported';

  /// Creates a confirmation asking the user to add the specified chain with [chainId], [chainName], [nativeCurrency], and [rpcUrls] to MetaMask.
  ///
  /// The user may choose to switch to the chain once it has been added.
  ///
  /// As with any method that causes a confirmation to appear, wallet_addEthereumChain should only be called as a result of direct user action, such as the click of a button.
  Future<void> walletAddChain({
    required String chainId,
    required String chainName,
    required CurrencyParams nativeCurrency,
    required List<String> rpcUrls,
    List<String>? blockExplorerUrls,
  }) =>
      request('wallet_addEthereumChain', [
        ChainParams(
          chainId: chainId,
          chainName: chainName,
          nativeCurrency: nativeCurrency,
          rpcUrls: rpcUrls,
        )
      ]);

  /// Requests that the user tracks the token with [address], [symbol], and [decimals] in MetaMask, [decimals] is optional.
  ///
  /// Returns `true` if token is successfully added.
  ///
  /// Ethereum protocal only support [type] that is `ERC20` for now.
  ///
  /// Most Ethereum wallets support some set of tokens, usually from a centrally curated registry of tokens. wallet_watchAsset enables web3 application developers to ask their users to track tokens in their wallets, at runtime. Once added, the token is indistinguishable from those added via legacy methods, such as a centralized registry.
  Future<bool> walletWatchAssets({
    required String address,
    required String symbol,
    required int decimals,
    String? image,
    String type = 'ERC20',
  }) =>
      request<bool>(
        'wallet_watchAsset',
        _WatchAssetParamsImpl(
          type: type,
          options: _WatchAssetOptionsImpl(
            decimals: decimals,
            symbol: symbol,
            address: address,
            image: image,
          ),
        ),
      );
}
