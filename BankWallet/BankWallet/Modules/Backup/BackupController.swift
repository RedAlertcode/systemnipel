import UIKit
import SnapKit
import ThemeKit

class BackupController: ThemeViewController {
    private let delegate: IBackupViewDelegate

    private let subtitleLabel = UILabel()
    private let cancelButton = ThemeButton()
    private let proceedButton = ThemeButton()

    init(delegate: IBackupViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = delegate.isBackedUp ? "backup.intro.title_show".localized : "backup.intro.title_backup".localized

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.marginTextSide)
            maker.top.equalTo(self.view.snp.topMargin).offset(CGFloat.margin6x)
        }

        subtitleLabel.text = "backup.intro.subtitle".localized(delegate.coinCodes)
        subtitleLabel.font = .body
        subtitleLabel.textColor = .themeGray
        subtitleLabel.numberOfLines = 0

        view.addSubview(proceedButton)
        proceedButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        proceedButton.apply(style: .primaryYellow)
        proceedButton.setTitle(delegate.isBackedUp ? "backup.intro.show_key".localized : "backup.intro.backup_now".localized, for: .normal)
        proceedButton.addTarget(self, action: #selector(proceedDidTap), for: .touchUpInside)

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(proceedButton.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin8x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle(delegate.isBackedUp ? "backup.close".localized : "backup.intro.later".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelDidTap), for: .touchUpInside)

    }

    @objc func proceedDidTap() {
        delegate.proceedDidTap()
    }

    @objc func cancelDidTap() {
        delegate.cancelDidClick()
    }

}
