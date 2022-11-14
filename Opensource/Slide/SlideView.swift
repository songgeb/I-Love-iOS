//
//  SldeView.swift
//  Test-Swift
//
//  Created by songgeb on 2022/11/12.
//  Copyright © 2022 songgeb.meitu.test. All rights reserved.
//

import UIKit

/// 横滑组件
class SlideView: UIView {
  // warning: hPadding must be greater or equal than interval
  /// cell距离collectionView左右边界的距离
  private let hPadding: CGFloat
  // cell距离collectionView上下边界的距离
  private let vPadding: CGFloat
  /// item 间距，默认8
  private let interval: CGFloat = 8

  private let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.backgroundColor = .clear
    scrollView.isPagingEnabled = true
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    return scrollView
  }()

  private let collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
    view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    view.showsVerticalScrollIndicator = false
    view.showsHorizontalScrollIndicator = false
    return view
  }()

  init(_ frame: CGRect, hPadding: CGFloat = 16, vPadding: CGFloat = 0) {
    self.hPadding = hPadding
    self.vPadding = vPadding
    super.init(frame: frame)
    setupView()
  }

  convenience override init(frame: CGRect) {
    self.init(frame)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    collectionView.dataSource = self
    scrollView.delegate = self
    collectionView.panGestureRecognizer.isEnabled = false
    collectionView.addGestureRecognizer(scrollView.panGestureRecognizer)

    addSubview(scrollView)
    addSubview(collectionView)
  }

  override func layoutSubviews() {
    collectionView.frame = bounds
    collectionView.contentInset = UIEdgeInsets(
      top: vPadding,
      left: hPadding,
      bottom: vPadding,
      right: hPadding)
    var frame = collectionView.frame
    let itemWidth = bounds.width - 2 * hPadding
    let itemHeight = collectionView.bounds.height
    // scrollView.bounds.width must be equal to itemsize.width + interval
    frame.size.width = itemWidth + interval
    frame.origin.x += collectionView.contentInset.left
    scrollView.frame = frame
    let count = collectionView.numberOfItems(inSection: 0)
    scrollView.contentSize = CGSize(
      width: CGFloat(count) * scrollView.bounds.width,
      height: itemHeight)

    // update layout's item size
    if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
       !CGSize(width: itemWidth, height: itemHeight).equalTo(layout.itemSize) {
      layout.minimumLineSpacing = interval
      layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
      layout.invalidateLayout()
    }
  }
}

extension SlideView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 10
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let colors: [UIColor] = [.red, .black, .orange, .brown, .green, .cyan, .purple]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.contentView.backgroundColor = colors[indexPath.item % colors.count]
    return cell
  }
}

extension SlideView: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // when the y of scrollview's contentoffset is 0, collectionView's contentoffset is -collectionView.contentInset.left
    var contentOffset = scrollView.contentOffset
    contentOffset.x -= collectionView.contentInset.left
    collectionView.contentOffset = contentOffset
  }
}
