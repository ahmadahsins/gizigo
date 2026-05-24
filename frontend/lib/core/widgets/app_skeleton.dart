import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFEDEDED),
    this.highlightColor = const Color(0xFFF8F8F8),
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin = EdgeInsets.zero,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class AppSkeletonCircle extends StatelessWidget {
  const AppSkeletonCircle({
    super.key,
    required this.size,
    this.margin = EdgeInsets.zero,
  });

  final double size;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class AppSkeletonLine extends StatelessWidget {
  const AppSkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius = 6,
    this.margin = EdgeInsets.zero,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

class AppSkeletonRecommendationCard extends StatelessWidget {
  const AppSkeletonRecommendationCard({
    super.key,
    this.imageSize = 88,
    this.imageBorderRadius = 16,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  final double imageSize;
  final double imageBorderRadius;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Container(
        margin: margin,
        child: Row(
          children: [
            AppSkeletonBox(
              width: imageSize,
              height: imageSize,
              borderRadius: imageBorderRadius,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonLine(width: 180, height: 18),
                  SizedBox(height: 8),
                  AppSkeletonLine(width: 130),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppSkeletonLine(width: 58, height: 24, borderRadius: 12),
                      AppSkeletonLine(width: 72, height: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
