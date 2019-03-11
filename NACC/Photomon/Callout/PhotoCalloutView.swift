import UIKit
import MapKit

@objc protocol CalloutViewDelegate {
    func mapView(_ mapView: MKMapView, didTap view: UIView, for annotation: MKAnnotation)
}

class PhotoCalloutView: CalloutView {
    @objc var imageData: UIImage?
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .callout)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .caption1)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 3
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    @objc override init(annotation: MKAnnotation) {
        super.init(annotation: annotation)
        configure()        
        updateContents(for: annotation)
    }
    
    @objc init(annotation: MKAnnotation, image: UIImage? = nil) {
        super.init(annotation: annotation)
        imageData = image
        configure()
        updateContents(for: annotation)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Should not call init(coder:)")
    }
    
    /// Update callout contents
    
    private func updateContents(for annotation: MKAnnotation) {
        titleLabel.text = annotation.title ?? "Unknown"
        subtitleLabel.text = annotation.subtitle ?? nil
        guard let image = imageData else {
            imageView.image = UIImage(named: "images/phototomon-logo.png")
            return
        }
        
        imageView.image = image
    }
    
    /// Add constraints for subviews of `contentView`
    
    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleTapped)))
        subtitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(subTitleTapped)))
        
        let views: [String: UIView] = [
            "imageView": imageView,
            "titleLabel": titleLabel,
            "subtitleLabel": subtitleLabel
        ]
        
        let vflStrings = [
            "V:|[imageView][imageView(==80)][titleLabel][subtitleLabel]|",
            "H:|[imageView(==80)]|",
            "H:|[titleLabel]|",
            "H:|[subtitleLabel]|",
        ]
        
        for vfl in vflStrings {
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: vfl, metrics: nil, views: views))
        }
    }
    
    // This is an example method, defined by `CalloutView`, which is called when you tap on the callout
    // itself (but not one of its subviews that have user interaction enabled).
    
    override func didTouchUpInCallout(_ sender: Any) {
        print("didTouchUpInCallout")
    }
    
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        if let mapView = mapView, let delegate = mapView.delegate as? CalloutViewDelegate {
            delegate.mapView(mapView, didTap: imageView, for: annotation!)
        }
    }
    
    @objc func titleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        if let mapView = mapView, let delegate = mapView.delegate as? CalloutViewDelegate {
            delegate.mapView(mapView, didTap: imageView, for: annotation!)
        }
    }
    
    @objc func subTitleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        if let mapView = mapView, let delegate = mapView.delegate as? CalloutViewDelegate {
            delegate.mapView(mapView, didTap: imageView, for: annotation!)
        }
    }
    
    /// Map view
    ///
    /// Navigate up view hierarchy until we find `MKMapView`.
    
    var mapView: MKMapView? {
        var view = superview
        while view != nil {
            if let mapView = view as? MKMapView { return mapView }
            view = view?.superview
        }
        return nil
    }
}
