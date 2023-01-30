public Mat processFrame(Mat input) {
        CAMERA_WIDTH = input.width();
        CAMERA_HEIGHT = input.height();
        try {
            // Process Image
            Imgproc.cvtColor(input, mat, Imgproc.COLOR_RGB2YCrCb);
            Core.inRange(mat, scalarLowerYCrCb, scalarUpperYCrCb, processed);
            // Remove Noise
            Imgproc.morphologyEx(processed, processed, Imgproc.MORPH_OPEN, new Mat());
            Imgproc.morphologyEx(processed, processed, Imgproc.MORPH_CLOSE, new Mat());
            // GaussianBlur
            Imgproc.GaussianBlur(processed, processed, new Size(5.0, 15.0), 0.00);
            // Find Contours
            List<MatOfPoint> contours = new ArrayList<>();
            Imgproc.findContours(processed, contours, new Mat(), Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE);

            // Draw Contours
            Imgproc.drawContours(input, contours, -1, new Scalar(255, 0, 0));

            // Lock this up to prevent errors when outside threads access the max rect property.
            synchronized (sync) {
                // Loop Through Contours
                for (MatOfPoint contour : contours) {
                    Point[] contourArray = contour.toArray();

                    // Bound Rectangle if Contour is Large Enough
                    if (contourArray.length >= 15) {
                        MatOfPoint2f areaPoints = new MatOfPoint2f(contourArray);
                        Rect rect = Imgproc.boundingRect(areaPoints);

                        if (                        rect.area() > maxArea
                                && rect.x + (rect.width / 2.0)  > (borderLeftX * CAMERA_WIDTH)
                                && rect.x + (rect.width / 2.0)  < CAMERA_WIDTH - (borderRightX * CAMERA_WIDTH)
                                && rect.y + (rect.height / 2.0) > (borderTopY * CAMERA_HEIGHT)
                                && rect.y + (rect.height / 2.0) < CAMERA_HEIGHT - (borderBottomY * CAMERA_HEIGHT)

                                || loopCounter - pLoopCounter   > 6
                                && rect.x + (rect.width / 2.0)  > (borderLeftX * CAMERA_WIDTH)
                                && rect.x + (rect.width / 2.0)  < CAMERA_WIDTH - (borderRightX * CAMERA_WIDTH)
                                && rect.y + (rect.height / 2.0) > (borderTopY * CAMERA_HEIGHT)
                                && rect.y + (rect.height / 2.0) < CAMERA_HEIGHT - (borderBottomY * CAMERA_HEIGHT)
                        ){
                            maxArea = rect.area();
                            maxRect = rect;
                            pLoopCounter++;
                            loopCounter = pLoopCounter;
                            first = true;
                        }
                        else if(loopCounter - pLoopCounter > 10){
                            maxArea = new Rect().area();
                            maxRect = new Rect();
                        }

                        areaPoints.release();
                    }
                    contour.release();
                }
                if (contours.isEmpty()) {
                    maxRect = new Rect(600,1,1,1);
                }
            }
            // Draw Rectangles If Area Is At Least 500
            if (first && maxRect.area() > 500) {
                Imgproc.rectangle(input, maxRect, new Scalar(0, 255, 0), 2);
            }
            // Draw Borders
            Imgproc.rectangle(input, new Rect(
                    (int) (borderLeftX * CAMERA_WIDTH),
                    (int) (borderTopY * CAMERA_HEIGHT),
                    (int) (CAMERA_WIDTH - (borderRightX * CAMERA_WIDTH) - (borderLeftX * CAMERA_WIDTH)),
                    (int) (CAMERA_HEIGHT - (borderBottomY * CAMERA_HEIGHT) - (borderTopY * CAMERA_HEIGHT))
            ), HOT_PINK, 2);

            // Display Data
            Imgproc.putText(input, "Area: " + getRectArea() + " Midpoint: " + getRectMidpointXY().x + " , " + getRectMidpointXY().y, new Point(5, CAMERA_HEIGHT - 5), 0, 0.6, new Scalar(255, 255, 255), 2);

            loopCounter++;
        } catch (Exception e) {
            debug = e;
            error = true;
        }
        return input;
    }
