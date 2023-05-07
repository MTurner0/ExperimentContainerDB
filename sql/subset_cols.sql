/* Subsets data by sample properties. */

SELECT featureID, assay.sampleID, value, binary_attribute
    FROM assay
    JOIN colData on assay.sampleID = colData.sampleID
    WHERE binary_attribute = 'B';