/*
Cleaning Data in SQL Queries
*/


SELECT *
FROM Training.dbo.NashvilleHousing


-- Standardize Date Format

SELECT SaleDate
FROM Training.dbo.NashvilleHousing

-- SaleDate has the time at the end. We want to take that off. Is a datetime format, so we're going to convert it.


SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM Training.dbo.NashvilleHousing

ALTER TABLE Training.dbo.NashvilleHousing
ADD SaleDateConverted Date

UPDATE Training.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


-- POPULATE PROPERTY ADDRESS DATA 

-- Check the NULL Values

SELECT PropertyAddress
FROM Training.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

-- We can see that there are NULL Values

SELECT *
FROM Training.dbo.NashvilleHousing
ORDER BY ParcelID

-- Same ParcelID has the same PropertyAddress. If the ParcelID has a PropertyAddress and there is a ParcelID with a NULL PropertyAddress, we're going to populate it.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Training.dbo.NashvilleHousing a
JOIN Training.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Training.dbo.NashvilleHousing a
JOIN Training.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM Training.dbo.NashvilleHousing

-- In the PropertyAdress column we have the address followed by a comma (,) and then the city.


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS Address
FROM Training.dbo.NashvilleHousing


ALTER TABLE Training.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE Training.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE Training.dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE Training.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))


SELECT *
FROM Training.dbo.NashvilleHousing     -- we can see the two new added columns


--Let's check the OwnwerAddress

SELECT OwnerAddress
FROM Training.dbo.NashvilleHousing

-- We're going to split the address by the delimiter.

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM Training.dbo.NashvilleHousing


ALTER TABLE Training.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE Training.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE Training.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE Training.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE Training.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE Training.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



SELECT *
FROM Training.dbo.NashvilleHousing     -- we can see the three new added columns



--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
FROM Training.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2




SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM Training.dbo.NashvilleHousing


UPDATE Training.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM Training.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress



SELECT *
FROM Training.dbo.NashvilleHousing


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


SELECT *
FROM Training.dbo.NashvilleHousing


ALTER TABLE Training.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate, PropertySplitCity


