/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble

@testable import lockbox_ios

class RootViewSpec : QuickSpec {
    class FakeRootPresenter:RootPresenter {
        var onViewReadyCalled = false

        override func onViewReady() {
            self.onViewReadyCalled = true
        }
    }

    private var presenter:FakeRootPresenter!
    var subject:RootView!

    override func spec() {
        describe("RootView") {
            beforeEach {
                self.subject = RootView()
                self.presenter = FakeRootPresenter(view: self.subject)

                self.subject.presenter = self.presenter
                
                self.subject.viewDidLoad()
            }

            it("informs the presenter on view load") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("loginStackDisplayed") {
                describe("without displaying the login stack") {
                    it("returns false") {
                        expect(self.subject.loginStackDisplayed).to(beFalse())
                    }
                }

                describe("displaying the login stack") {
                    beforeEach {
                        self.subject.startLoginStack()
                    }

                    it("returns true") {
                        expect(self.subject.loginStackDisplayed).to(beTrue())
                    }
                }
            }

            describe("mainStackDisplayed") {
                describe("without displaying the main stack") {
                    it("returns false") {
                        expect(self.subject.mainStackDisplayed).to(beFalse())
                    }
                }

                describe("displaying the main stack") {
                    beforeEach {
                        self.subject.startMainStack()
                    }

                    it("returns true") {
                        expect(self.subject.mainStackDisplayed).to(beTrue())
                    }
                }
            }

            describe("pushing login views") {
                describe("login") {
                    beforeEach {
                        self.subject.startLoginStack()
                        self.subject.pushLoginView(view: LoginRouteAction.welcome)
                    }

                    it("makes a loginview the top view") {
                        expect(self.subject.topViewIs(WelcomeView.self)).to(beTrue())
                    }
                }

                describe("fxa") {
                    beforeEach {
                        self.subject.startLoginStack()
                        self.subject.pushLoginView(view: LoginRouteAction.fxa)
                    }

                    it("makes an fxaview the top view") {
                        expect(self.subject.topViewIs(FxAView.self)).toEventually(beTrue())
                    }
                }
            }

            describe("displaying main stack after login stack") {
                beforeEach {
                    self.subject.startLoginStack()
                    self.subject.startMainStack()
                }

                it("displays the main stack only") {
                    expect(self.subject.loginStackDisplayed).to(beFalse())
                    expect(self.subject.mainStackDisplayed).to(beTrue())
                }
            }

            describe("required init") {
                beforeEach {
                    let testBundle = Bundle.allBundles.filter { bundle in
                        bundle.bundlePath.contains("xctest") && !bundle.bundlePath.contains("Frameworks")
                     }.first

                    self.subject = UIStoryboard.init(name: "RootViewSpec", bundle: testBundle).instantiateViewController(withIdentifier: "root") as! RootView
                }

                it("works") {
                    expect(self.subject.presenter).notTo(beNil())
                }
            }
        }
    }
}
