import 'package:flutter/material.dart';

class ArrowConnectorPainter extends CustomPainter {
  Offset initialPoint;
  Offset currentPoint;
  final double connectorSize;

  ArrowConnectorPainter({
    required this.currentPoint,
    required this.initialPoint,
    required this.connectorSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(connectorSize / 2, connectorSize / 2)
      ..lineTo(currentPoint.dx, currentPoint.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ArrowConnector extends StatefulWidget {
  final Function() onDragStart;
  final Function() onDragEnd;
  final double size;

  const ArrowConnector({
    super.key,
    required this.onDragStart,
    required this.onDragEnd,
    required this.size,
  });

  @override
  State<ArrowConnector> createState() => _ArrowConnectorState();
}

class _ArrowConnectorState extends State<ArrowConnector> {
  late Offset currentPoint;

  @override
  void initState() {
    currentPoint = Offset(widget.size / 2, widget.size / 2);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        setState(() {
          currentPoint = Offset(
            currentPoint.dx + details.delta.dx,
            currentPoint.dy + details.delta.dy,
          );
        });
      },
      onPanDown: (details) {
        widget.onDragStart();
        setState(() {
          currentPoint = details.localPosition;
        });
      },
      onPanEnd: (details) {
        widget.onDragEnd();
        setState(() {
          currentPoint = Offset(widget.size / 2, widget.size / 2);
        });
      },
      child: CustomPaint(
        painter: ArrowConnectorPainter(
          initialPoint: Offset(widget.size, widget.size),
          currentPoint: currentPoint,
          connectorSize: widget.size,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
