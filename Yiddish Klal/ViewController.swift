//
//  ViewController.swift
//  Yiddish Klal - A Standard Yiddish keyboard layout for iOS
//  Created by Isaac L. Bleaman (bleaman@berkeley.edu)
//  Distributed by Leyenzal - A Yiddish Literacy Project (leyenzal.org)
//  Copyright © 2026 Isaac L. Bleaman.
//  Documentation: https://www.isaacbleaman.com/resources/yiddish_typing/
//  License: CC BY-SA 4.0
//

import UIKit

class ViewController: UIViewController {
    
    var currentLanguage: Language = .english
    var titleLabel: UILabel!
    var instructionsLabel: UILabel!
    var linkButton: UIButton!
    var settingsButton: UIButton!
    var footnoteLabel: UILabel!
    
    // Delete toggle components
    var deleteToggleLabel: UILabel!
    var deleteToggle: UISwitch!
    var deleteDescriptionLabel: UILabel!
    
    enum Language {
        case english
        case yiddish
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // Create scroll view
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Language selector
        let languageControl = UISegmentedControl(items: ["English", "ייִדיש"])
        languageControl.selectedSegmentIndex = 0
        languageControl.addTarget(self, action: #selector(languageChanged), for: .valueChanged)
        languageControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(languageControl)
        
        // Title
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Instructions
        instructionsLabel = UILabel()
        instructionsLabel.font = UIFont.systemFont(ofSize: 16)
        instructionsLabel.numberOfLines = 0
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(instructionsLabel)
        
        // Website link
        linkButton = UIButton(type: .system)
        linkButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        linkButton.addTarget(self, action: #selector(openWebsite), for: .touchUpInside)
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(linkButton)
        
        // Delete toggle section
        deleteToggleLabel = UILabel()
        deleteToggleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        deleteToggleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteToggleLabel)
        
        deleteToggle = UISwitch()
        deleteToggle.isOn = UserDefaults(suiteName: "group.org.leyenzal.yiddishklal")?.bool(forKey: kDeleteEntireGrapheme) ?? true
        deleteToggle.addTarget(self, action: #selector(deleteToggleChanged), for: .valueChanged)
        deleteToggle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteToggle)
        
        deleteDescriptionLabel = UILabel()
        deleteDescriptionLabel.font = UIFont.systemFont(ofSize: 13)
        deleteDescriptionLabel.textColor = .darkGray
        deleteDescriptionLabel.numberOfLines = 0
        deleteDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteDescriptionLabel)
        
        // Settings button (proper button style)
        settingsButton = UIButton(type: .system)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        settingsButton.backgroundColor = .systemBlue
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.layer.cornerRadius = 10
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(settingsButton)
        
        // Footnote
        footnoteLabel = UILabel()
        footnoteLabel.font = UIFont.systemFont(ofSize: 13)
        footnoteLabel.textColor = .gray
        footnoteLabel.numberOfLines = 0
        footnoteLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(footnoteLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            languageControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            languageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: languageControl.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            instructionsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            linkButton.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 10),
            linkButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Delete toggle section
            deleteToggleLabel.topAnchor.constraint(equalTo: linkButton.bottomAnchor, constant: 30),
            deleteToggleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            deleteToggle.centerYAnchor.constraint(equalTo: deleteToggleLabel.centerYAnchor),
            deleteToggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            deleteToggle.leadingAnchor.constraint(greaterThanOrEqualTo: deleteToggleLabel.trailingAnchor, constant: 10),
            
            deleteDescriptionLabel.topAnchor.constraint(equalTo: deleteToggleLabel.bottomAnchor, constant: 8),
            deleteDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            deleteDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            settingsButton.topAnchor.constraint(equalTo: deleteDescriptionLabel.bottomAnchor, constant: 30),
            settingsButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 250),
            settingsButton.heightAnchor.constraint(equalToConstant: 50),
            
            footnoteLabel.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 20),
            footnoteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            footnoteLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            footnoteLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
        
        updateContent()
    }
    
    @objc func languageChanged(_ sender: UISegmentedControl) {
        currentLanguage = sender.selectedSegmentIndex == 0 ? .english : .yiddish
        updateContent()
    }
    
    @objc func deleteToggleChanged(_ sender: UISwitch) {
        UserDefaults(suiteName: "group.org.leyenzal.yiddishklal")?.set(sender.isOn, forKey: kDeleteEntireGrapheme)
    }
    
    func updateContent() {
        switch currentLanguage {
        case .english:
            titleLabel.text = "Yiddish Klal\nייִדיש כּלל"
            titleLabel.textAlignment = .center
            
            instructionsLabel.text = """
            You have successfully installed Yiddish Klal, a QWERTY-based keyboard for Standard Yiddish on iOS.
            
            To enable the keyboard:
            
            1. Tap the "Open Settings" button below
            2. On the next screen, tap "Keyboards" at the bottom  
            3. Toggle ON "YiddishKlalKeyboard"
            
            To use the keyboard:
            
            • Tap the globe icon (🌐) to switch keyboards
            • Tap "123" to access numbers and symbols  
            • Tap shift (⇧) for alternate characters
            
            The layout follows QWERTY positions for easy typing. For detailed instructions and the full character map, visit:
            """
            instructionsLabel.textAlignment = .left
            instructionsLabel.semanticContentAttribute = .forceLeftToRight
            
            linkButton.setTitle("isaacbleaman.com/resources/yiddish_typing", for: .normal)
            settingsButton.setTitle("Open Settings", for: .normal)
            
            footnoteLabel.text = "Note: iOS may automatically add an additional Hebrew or Yiddish keyboard after you start using Yiddish Klal. You can delete this extra keyboard (and keep Yiddish Klal) in Settings → General → Keyboard → Keyboards."
            footnoteLabel.textAlignment = .center
            footnoteLabel.semanticContentAttribute = .forceLeftToRight
            deleteToggleLabel.text = "Delete entire grapheme"
            deleteDescriptionLabel.text = "When ON (default), tapping backspace once will delete a complete letter including any diacritics (אַ). When OFF, tapping backspace once will delete just the diacritic (אַ becomes א); tapping backspace a second time deletes the letter."
            
        case .yiddish:
            titleLabel.text = "ייִדיש כּלל\nYiddish Klal"
            titleLabel.textAlignment = .center
            
            instructionsLabel.text = """
            איר האָט בהצלחה אינסטאַלירט די אַפּליקאַציע „ייִדיש כּלל", אַ QWERTY־קלאַװיאַטור אױף iOS פֿאַר די װאָס װילן אױסקלאַפּן טעקסטן לױטן אײנהײטלעכן ייִדישן אױסלײג („ייִװאָ־אױסלײג").
                        
            װי אַזױ צו דערמעגלעכן די קלאַװיאַטור:
            
            1. גיט אַ קװעטש אױפֿן קנעפּל „עפֿענען פֿיקסירונגען“ אונטן
            2. אױפֿן װײַטערדיקן עקראַן, גיט אַ קװעטש אױף „Keyboards“ סאַמע אונטן
            3. שטעלט אָן: YiddishKlalKeyboard
            
            װי אַזױ זיך צו באַניצן מיט דער קלאַװיאַטור:
            
            • גיט אַ קװעטש אױפֿן גלאָבוס (🌐) צו בײַטן קלאַװיאַטורן
            • גיט אַ קװעטש אױף "123" כּדי צוצוקומען צו די ציפֿערן און סימבאָלן
            • גיט אַ קװעטש אױף Shift (⇧) פֿאַר אַלטערנאַטיװן הינטער יעדן קלאַװיש
            
            דער אױסשטעל פֿון די אותיות איז באַזירט אױף דער QWERTY־קלאַװיטור פֿאַר לאַטײַניש/ענגליש. פּרטימדיקע אָנװײַזונגען קען מען געפֿינען אָט דאָ:
            """
            instructionsLabel.textAlignment = .right
            instructionsLabel.semanticContentAttribute = .forceRightToLeft
            
            linkButton.setTitle("isaacbleaman.com/resources/yiddish_typing", for: .normal)
            settingsButton.setTitle("עפֿענען פֿיקסירונגען", for: .normal)
            
            footnoteLabel.text = "זײַט װיסן: iOS װעט אפֿשר אינסטאַלירן אַ צװײטע העברעיִשע אָדער ייִדישע קלאַװיאַטור נאָך דעם װאָס איר באַניצט זיך מיט ייִדיש כּלל. איר קענט אָפּמעקן די איבעריקע קלאַװיאַטור (און האַלטן ייִדיש כּלל) אין Settings."
            footnoteLabel.textAlignment = .center
            footnoteLabel.semanticContentAttribute = .forceRightToLeft
            deleteToggleLabel.text = "אױסמעקן גאַנצע אותיות"
            deleteDescriptionLabel.text = "װען אָנגעצונדן (גרין): קװעטשן אױפֿן קריקקלאַװיש װעט אָפּמעקן אַ גאַנצן אות צוזאַמען מיט זײַנע דיאַקריטלעך (למשל, אַ). װען אױסגעלאָשן: קװעטשן אױפֿן קריקקלאַװיש װעט קודם אָפּמעקן דאָס דיאַקריטל (אַ װערט א), דערנאָכדעם דעם אות גופֿא."
        }
    }
    
    @objc func openWebsite() {
        if let url = URL(string: "https://www.isaacbleaman.com/resources/yiddish_typing/") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

let kDeleteEntireGrapheme = "kDeleteEntireGrapheme"
