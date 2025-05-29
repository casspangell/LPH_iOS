//
//  AboutSongController.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 13/12/17.
//  Updated by Cass Pangell on 9/4/21.
//  Copyright © 2017 LovePeaceHarmony. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import AVFoundation
import AVKit

class AboutSongController: BaseViewController, IndicatorInfoProvider {

    // MARK: Variables
    
    var constraintCalculated = false
    private var videoCoverImageView: UIImageView?
    
    // MARK: - IBOutlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewVideoContainer: UIView!
    @IBOutlet weak var viewLoadingContainer: UIView!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var labelTitle: UILabel!
    
    @IBOutlet weak var descriptionOne: UILabel!
    @IBOutlet weak var descriptionTwo: UILabel!
    @IBOutlet weak var descriptionThree: UILabel!
    @IBOutlet weak var descriptionFour: UILabel!
    
    // MARK: - Views
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Remove any previous subviews (e.g., old YTPlayerView or cover)
        viewVideoContainer.subviews.forEach { $0.removeFromSuperview() }
        activityIndicator.stopAnimating()
        viewLoadingContainer.isHidden = true

        // Generate and show the first frame as cover
        if let coverImage = getFirstFrameOfVideo() {
            let coverImageView = UIImageView(image: coverImage)
            coverImageView.contentMode = .scaleAspectFill
            coverImageView.clipsToBounds = true
            coverImageView.frame = viewVideoContainer.bounds
            coverImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            viewVideoContainer.addSubview(coverImageView)
            videoCoverImageView = coverImageView
        }

        // Add a play button overlay
        let playButton = UIButton(type: .custom)
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        playButton.layer.cornerRadius = 32
        playButton.clipsToBounds = true
        playButton.frame = CGRect(x: (viewVideoContainer.bounds.width - 64) / 2, y: (viewVideoContainer.bounds.height - 64) / 2, width: 64, height: 64)
        playButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        playButton.addTarget(self, action: #selector(playLocalVideo), for: .touchUpInside)
        viewVideoContainer.addSubview(playButton)

        let songTitle = NSMutableAttributedString(string: NSLocalizedString(AboutDescription.songTitle, comment: "") )
        labelTitle.attributedText = songTitle
        
        let songDescription = NSLocalizedString(AboutDescription.songDescription, comment: "")
        let songDescription2 = NSLocalizedString(AboutDescription.songDescription2, comment: "")
        let songDescription3 = NSLocalizedString(AboutDescription.songDescription3, comment: "")
        let songDescription4 = NSLocalizedString(AboutDescription.songDescription4, comment: "")
        
        descriptionOne.text = songDescription
        descriptionTwo.text = songDescription2
        descriptionThree.text = songDescription3
        descriptionFour.text = songDescription4
    }

    @objc func playLocalVideo() {
        guard let videoURL = Bundle.main.url(forResource: "how_to_change_the_world", withExtension: "mp4") else {
            print("Error: Could not find how_to_change_the_world.mp4")
            showVideoError()
            return
        }
        
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        present(playerViewController, animated: true) {
            player.play()
        }
    }

    func showVideoError() {
        let alert = UIAlertController(title: "Video Error", message: "Unable to load video", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func getFirstFrameOfVideo() -> UIImage? {
        guard let videoURL = Bundle.main.url(forResource: "how_to_change_the_world", withExtension: "mp4") else {
            return nil
        }
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        do {
            let cgImage = try imageGenerator.copyCGImage(at: kCMTimeZero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating video cover image: \(error)")
            return nil
        }
    }

    // MARK: - XLPagerTabStrip
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Title")
    }
}
