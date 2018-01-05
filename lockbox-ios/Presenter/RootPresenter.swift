/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

protocol RootViewProtocol: class {
    func topViewIs<T>(_ class: T.Type) -> Bool

    var loginStackDisplayed:Bool { get }
    func startLoginStack()
    func pushLoginView(view: LoginRouteAction)

    var mainStackDisplayed:Bool { get }
    func startMainStack()
//    func pushMainView(view: MainRouteAction)
}

typealias InfoKeyInitTriple = (profileInfo:ProfileInfo, scopedKey:String, initialized:Bool)
typealias UidKeyTuple = (uid: String, scopedKey: String)
typealias KeyLockTuple = (scopedKey: String, locked: Bool)

class RootPresenter {
    private weak var view: RootViewProtocol!
    private let disposeBag = DisposeBag()

    fileprivate let routeStore:RouteStore
    fileprivate let userInfoStore:UserInfoStore
    fileprivate let dataStore:DataStore
    fileprivate let routeActionHandler:RouteActionHandler
    fileprivate let dataStoreActionHandler:DataStoreActionHandler

    init(view:RootViewProtocol,
         routeStore:RouteStore = RouteStore.shared,
         userInfoStore:UserInfoStore = UserInfoStore.shared,
         dataStore:DataStore = DataStore.shared,
         routeActionHandler:RouteActionHandler = RouteActionHandler.shared,
         dataStoreActionHandler:DataStoreActionHandler = DataStoreActionHandler.shared
    ) {
        self.view = view
        self.routeStore = routeStore
        self.userInfoStore = userInfoStore
        self.dataStore = dataStore
        self.routeActionHandler = routeActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler

        // request init & lock status update on app launch
        self.dataStoreActionHandler.updateInitialized()
        self.dataStoreActionHandler.updateLocked()

        // initialize if not initialized
        Observable.combineLatest(self.userInfoStore.profileInfo, self.userInfoStore.scopedKey, self.dataStore.onInitialized)
                .filter { (triple:InfoKeyInitTriple) in
                    return triple.profileInfo.uid.isEmpty == triple.scopedKey.isEmpty
                }
                .subscribe(onNext: { (triple:InfoKeyInitTriple) in
                    // what happens when they are both empty and the datastore is initialized?
                    if triple.profileInfo.uid.isEmpty && triple.scopedKey.isEmpty {
                        self.routeActionHandler.invoke(LoginRouteAction.welcome)
                    } else if !triple.initialized {
                        // possible side case: getting an update to the scopedKey & uid on a logout / login
                        // handle here or with DataStore interaction? need to overwrite initialized value...
                        self.dataStoreActionHandler.initialize(scopedKey: triple.scopedKey, uid: triple.profileInfo.uid)
                    }
                })
                .disposed(by: self.disposeBag)

        // blindly unlock for now
        Observable.combineLatest(self.userInfoStore.scopedKey, self.dataStore.onLocked)
                .filter { (pair: KeyLockTuple) in
                    return !pair.scopedKey.isEmpty && pair.locked
                }
                .subscribe(onNext: { (pair: KeyLockTuple) in
                    if pair.locked {
                        self.dataStoreActionHandler.unlock(scopedKey: pair.scopedKey)
                    }
                })
                .disposed(by: self.disposeBag)
    }

    func onViewReady() {
        // listen for explicit route actions
        self.routeStore.onRoute
                .filterByType(class: LoginRouteAction.self)
                .asDriver(onErrorJustReturn: .welcome)
                .drive(showLogin)
                .disposed(by: disposeBag)

        self.routeStore.onRoute
                .filterByType(class: MainRouteAction.self)
                .asDriver(onErrorJustReturn: .list)
                .drive(showList)
                .disposed(by: disposeBag)
    }

    fileprivate var showLogin:AnyObserver<LoginRouteAction> {
        return Binder(self) { target, loginAction in
            if !self.view.loginStackDisplayed {
                self.view.startLoginStack()
            }

            switch loginAction {
                case .welcome:
                    if !self.view.topViewIs(WelcomeView.self) {
                        self.view.pushLoginView(view: .welcome)
                    }
                case .fxa:
                    if !self.view.topViewIs(FxAView.self) {
                        self.view.pushLoginView(view: .fxa)
                    }
            }
        }.asObserver()
    }

    fileprivate var showList:AnyObserver<MainRouteAction> {
        return Binder(self) { target, mainAction in
            switch mainAction {
            case .list: break
            case .detail(_): break
            }
        }.asObserver()
    }
}
