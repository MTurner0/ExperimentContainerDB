/* NOTE: Use of log()/ln() requires sqlite >=3.35 */

SELECT LN(value/size + 1) AS norm_val
    FROM assay
    JOIN (SELECT sampleID, SUM(value) AS size
            FROM assay
            GROUP BY sampleID) AS agg
    ON assay.sampleID = agg.sampleID;