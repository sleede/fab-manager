// TODO: Remove next eslint-disable
/* eslint-disable @typescript-eslint/no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useImmer } from 'use-immer';
import { ProductCategory } from '../../../models/product-category';
import { DndContext, KeyboardSensor, PointerSensor, useSensor, useSensors, closestCenter, DragMoveEvent } from '@dnd-kit/core';
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { restrictToWindowEdges } from '@dnd-kit/modifiers';
import { ProductCategoriesItem } from './product-categories-item';

interface ProductCategoriesTreeProps {
  productCategories: Array<ProductCategory>,
  onDnd: (list: Array<ProductCategory>) => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a tree list of all Product's Categories
 */
export const ProductCategoriesTree: React.FC<ProductCategoriesTreeProps> = ({ productCategories, onDnd, onSuccess, onError }) => {
  const [categoriesList, setCategoriesList] = useImmer<ProductCategory[]>(productCategories);
  const [activeData, setActiveData] = useImmer<ActiveData>(initActiveData);
  // TODO: type extractedChildren: {[parentId]: ProductCategory[]} ???
  const [extractedChildren, setExtractedChildren] = useImmer({});
  const [collapsed, setCollapsed] = useImmer<number[]>([]);
  const [offset, setOffset] = useState<boolean>(false);

  // Initialize state from props
  useEffect(() => {
    setCategoriesList(productCategories);
  }, [productCategories]);

  // Dnd Kit config
  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates
    })
  );

  /**
   * On drag start
   * Collect dragged items' data
   * Extract children from list
   */
  const handleDragStart = ({ active }: DragMoveEvent) => {
    const activeIndex = active.data.current.sortable.index;
    const children = getChildren(active.id);

    setActiveData(draft => {
      draft.index = activeIndex;
      draft.category = getCategory(active.id);
      draft.status = getStatus(active.id);
      draft.children = children?.length ? children : null;
    });

    setExtractedChildren(draft => { draft[active.id] = children; });
    hideChildren(active.id, activeIndex);
  };

  /**
   * On drag move
   */
  const handleDragMove = ({ delta, active, over }: DragMoveEvent) => {
    if ((getStatus(active.id) === 'single' || getStatus(active.id) === 'child') && getStatus(over.id) === 'single') {
      if (delta.x > 32) {
        setOffset(true);
      } else {
        setOffset(false);
      }
    }
  };

  /**
   * On drag End
   * Insert children back in list
   */
  const handleDragEnd = ({ active, over }: DragMoveEvent) => {
    let newOrder = [...categoriesList];
    const currentIdsOrder = over?.data.current.sortable.items;
    let newIndex = over.data.current.sortable.index;

    // [A] Single |> [B] Single
    if (getStatus(active.id) === 'single' && getStatus(over.id) === 'single') {
      console.log('[A] Single |> [B] Single');
      const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
      newOrder = newIdsOrder.map(sortedId => {
        let category = getCategory(sortedId);
        if (offset && sortedId === active.id && activeData.index < newIndex) {
          category = { ...category, parent_id: Number(over.id) };
        }
        return category;
      });
    }

    // [A] Child |> [B] Single
    if ((getStatus(active.id) === 'child') && getStatus(over.id) === 'single') {
      console.log('[A] Child |> [B] Single');
      const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
      newOrder = newIdsOrder.map(sortedId => {
        let category = getCategory(sortedId);
        if (offset && sortedId === active.id && activeData.index < newIndex) {
          category = { ...category, parent_id: Number(over.id) };
        } else if (sortedId === active.id && activeData.index < newIndex) {
          category = { ...category, parent_id: null };
        }
        return category;
      });
    }

    // [A] Single || Child |>…
    if (getStatus(active.id) === 'single' || getStatus(active.id) === 'child') {
      // [B] Parent
      if (getStatus(over.id) === 'parent') {
        if (activeData.index < newIndex) {
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => {
            let category = getCategory(sortedId);
            if (sortedId === active.id) {
              category = { ...category, parent_id: Number(over.id) };
            }
            return category;
          });
        } else {
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => {
            let category = getCategory(sortedId);
            if (sortedId === active.id) {
              category = { ...category, parent_id: null };
            }
            return category;
          });
        }
      }
      // [B] Child
      if (getStatus(over.id) === 'child') {
        const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
        newOrder = newIdsOrder.map(sortedId => {
          let category = getCategory(sortedId);
          if (sortedId === active.id) {
            category = { ...category, parent_id: getCategory(over.id).parent_id };
          }
          return category;
        });
      }
    }

    // [A] Parent |>…
    if (getStatus(active.id) === 'parent') {
      // [B] Single
      if (getStatus(over.id) === 'single') {
        const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
        newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
      }
      // [B] Parent
      if (getStatus(over.id) === 'parent') {
        if (activeData.index < newIndex) {
          const lastOverChildIndex = newOrder.findIndex(c => c.id === getChildren(over.id).pop().id);
          newIndex = lastOverChildIndex;
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
        } else {
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
        }
      }
      // [B] Child
      if (getStatus(over.id) === 'child') {
        if (activeData.index < newIndex) {
          const parent = newOrder.find(c => c.id === getCategory(over.id).parent_id);
          const lastSiblingIndex = newOrder.findIndex(c => c.id === getChildren(parent.id).pop().id);
          newIndex = lastSiblingIndex;
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
        } else {
          const parentIndex = currentIdsOrder.indexOf(getCategory(over.id).parent_id);
          newIndex = parentIndex;
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
        }
      }
      // insert children back
      newOrder = showChildren(active.id, newOrder, newIndex);
    }

    onDnd(newOrder);
    setOffset(false);
  };

  /**
   * On drag cancel
   * Reset states
   */
  const handleDragCancel = ({ active }: DragMoveEvent) => {
    setCategoriesList(productCategories);
    setActiveData(initActiveData);
    setExtractedChildren({ ...extractedChildren, [active.id]: null });
  };

  /**
   * Get a category by its id
   */
  const getCategory = (id) => {
    return categoriesList.find(c => c.id === id);
  };

  /**
   * Get the children categories of a parent category by its id
   */
  const getChildren = (id) => {
    const displayedChildren = categoriesList.filter(c => c.parent_id === id);
    if (displayedChildren.length) {
      return displayedChildren;
    }
    return extractedChildren[id];
  };

  /**
   * Get category's status by its id
   * child | single | parent
   */
  const getStatus = (id) => {
    const c = getCategory(id);
    return !c.parent_id
      ? getChildren(id)?.length
        ? 'parent'
        : 'single'
      : 'child';
  };

  /**
   * Extract children from the list by their parent's id
   */
  const hideChildren = (parentId, parentIndex) => {
    const children = getChildren(parentId);
    if (children?.length) {
      const shortenList = [...categoriesList];
      shortenList.splice(parentIndex + 1, children.length);
      setCategoriesList(shortenList);
    }
  };

  /**
   * Insert children back in the list by their parent's id
   */
  const showChildren = (parentId, currentList, insertIndex) => {
    if (extractedChildren[parentId]?.length) {
      currentList.splice(insertIndex + 1, 0, ...extractedChildren[parentId]);
      setExtractedChildren({ ...extractedChildren, [parentId]: null });
    }
    return currentList;
  };

  /**
   * Toggle parent category by hidding/showing its children
   */
  const handleCollapse = (id) => {
    const i = collapsed.findIndex(el => el === id);
    if (i === -1) {
      setCollapsed([...collapsed, id]);
    } else {
      const copy = [...collapsed];
      copy.splice(i, 1);
      setCollapsed(copy);
    }
  };

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      modifiers={[restrictToWindowEdges]}
      onDragStart={handleDragStart}
      onDragMove={handleDragMove}
      onDragEnd={handleDragEnd}
      onDragCancel={handleDragCancel}
    >
      <SortableContext items={categoriesList} strategy={verticalListSortingStrategy}>
        <div className='product-categories-tree'>
          {categoriesList
            .map((category) => (
              <ProductCategoriesItem key={category.id}
                productCategories={productCategories}
                category={category}
                onSuccess={onSuccess}
                onError={onError}
                offset={category.id === activeData.category?.id && activeData?.offset}
                collapsed={collapsed.includes(category.id) || collapsed.includes(category.parent_id)}
                handleCollapse={handleCollapse}
                status={getStatus(category.id)}
              />
            ))}
        </div>
      </SortableContext>
    </DndContext>
  );
};

interface ActiveData {
  index: number,
  category: ProductCategory,
  status: 'child' | 'single' | 'parent',
  children: ProductCategory[],
  offset: boolean
}
const initActiveData: ActiveData = {
  index: null,
  category: null,
  status: null,
  children: [],
  offset: false
};
