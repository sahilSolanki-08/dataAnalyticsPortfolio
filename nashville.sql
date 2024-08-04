-- first view

SELECT * 
FROM projectPortfolio..[NashvilleHousingData]
ORDER BY ParcelID

--56477 rows

-- update data type for date column

UPDATE [NashvilleHousingData]
SET SaleDate = CONVERT(date, SaleDate)

-- now there are null addresses which exist, match them using the parcelID values, using join table 
-- VERY IMPORTANT

SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [NashvilleHousingData] as a 
JOIN [NashvilleHousingData] as b
    ON a.ParcelID =  b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

-- the above table is useful to join the two tables (on itself) and see where you are getting null values, and find the corresponding address using the unique IDs

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [NashvilleHousingData] as a 
JOIN [NashvilleHousingData] as b
    ON a.ParcelID =  b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

-- kinda like a temporary table but not exactly 
-- now we update the column using the above made join table and update clause


-- divide address into city, state, address
-- we use a combination of substring and charindex
-- charindex - 1 is done to not include the comma in the output

SELECT 
    SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM projectPortfolio..[NashvilleHousingData]

-- now use alter table to add the columns (alter se column add kra, update se value set kr di)

alter table NashvilleHousingData
add addressSplit nvarchar(255)

update NashvilleHousingData
set addressSplit = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

alter table NashvilleHousingData
add citySplit nvarchar(255)

update NashvilleHousingData
set citySplit = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

-- now we divide the owners address by the same thing but we want to do it quicker (using parsename)
-- parsename(column_name, part_index), but it searches for full stops so we use, replace(column_name, icon to be replaced, icon to be replaced with)
-- also parsename stars separating things from the end of the string

SELECT 
    PARSENAME(REPLACE(OwnerAddress,',','.'),3),
    PARSENAME(REPLACE(OwnerAddress,',','.'),2),
    PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM NashvilleHousingData

-- now add these to the table

alter table NashvilleHousingData
add ownerSplit nvarchar(255)

update NashvilleHousingData
set ownerSplit = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

alter table NashvilleHousingData
add ownerCity nvarchar(255)

update NashvilleHousingData
set ownerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

alter table NashvilleHousingData
add ownerState nvarchar(255)

update NashvilleHousingData
set ownerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- our table has n, no, y, yes; convert all y to yes and all n to no
-- first we find distinct values of each

SELECT distinct(SoldAsVacant), count(SoldAsVacant) as counts
FROM NashvilleHousingData
group by SoldAsVacant
order by counts

-- now we use update and case to switch it 

UPDATE NashvilleHousingData
SET SoldAsVacant =
    CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END

-- removing duplicates (now we will remove them permanently, but better practice is to store that information elsewhere)
-- When the SQL Server ROW NUMBER function detects two identical values in the same partition, it assigns different rank numbers to both.
-- now after finding the duplicates (where row number gave a different number); we use a temp table to delete them

WITH RowNum AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION by ParcelID,
                        PropertyAddress,
                        SalePrice,
                        SaleDate,
                        LegalReference
            Order by UniqueID
        ) as row_num
    from NashvilleHousingData
)
DELETE -- using delete to delete the respective rows
FROM RowNum
WHERE row_num > 1

-- delete unused columns by using alter & drop





