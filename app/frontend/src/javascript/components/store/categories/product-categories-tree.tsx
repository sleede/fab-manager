/* eslint-disable @typescript-eslint/no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useImmer } from 'use-immer';
import { ProductCategory } from '../../../models/product-category';
import { DndContext, KeyboardSensor, PointerSensor, useSensor, useSensors, closestCenter, DragMoveEvent } from '@dnd-kit/core';
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from '@dnd-kit/sortable';
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
  const [hiddenChildren, setHiddenChildren] = useState({});

  // Initialize state from props, sorting list as a tree
  useEffect(() => {
    setCategoriesList(productCategories);
  }, [productCategories]);

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates
    })
  );

  /**
   * On drag start
   */
  const handleDragStart = ({ active }: DragMoveEvent) => {
    hideChildren(active.id, categoriesList.findIndex(el => el.id === active.id));
    const activeChildren = categoriesList.filter(c => c.parent_id === active.id);
    if (activeChildren.length) {
      setHiddenChildren({ [active.id]: activeChildren });
      const activeIndex = categoriesList.findIndex(el => el.id === active.id);
      const tmpList = [...categoriesList];
      tmpList.splice(activeIndex + 1, activeChildren.length);
      setCategoriesList(tmpList);
    }
  };

  /**
   * On drag move
   */
  const handleDragMove = ({ delta, over }: DragMoveEvent) => {
    console.log(findCategory(over.id).name);
    if (delta.x > 48) {
      console.log('Child');
    } else {
      console.log('Parent');
    }
  };

  /**
   * Update categories list after an item was dropped
   */

  const handleDragEnd = ({ active, over }: DragMoveEvent) => {
    let newOrder = [...categoriesList];

    // si déplacé sur une autre catégorie…
    if (active.id !== over.id) {
      // liste d'ids des catégories visibles
      const previousIdsOrder = over?.data.current.sortable.items;
      // index dans previousIdsOrder de la catégorie déplacée
      const oldIndex = active.data.current.sortable.index;
      // index dans previousIdsOrder de la catégorie de réception
      const newIndex = over.data.current.sortable.index;
      // liste de catégories mise à jour après le drop
      const newIdsOrder = arrayMove(previousIdsOrder, oldIndex, newIndex);
      // id du parent de la catégorie de réception
      const newParentId = categoriesList[newIndex].parent_id;

      // nouvelle liste de catégories classées par newIdsOrder
      newOrder = newIdsOrder.map(sortedId => {
        // catégorie courante du map retrouvée grâce à l'id
        const categoryFromId = findCategory(sortedId);
        // si catégorie courante = catégorie déplacée…
        if (categoryFromId.id === active.id) {
          // maj du parent
          categoryFromId.parent_id = newParentId;
        }
        // retour de la catégorie courante
        return categoryFromId;
      });
    }
    // insert siblings back
    if (hiddenChildren[active.id]?.length) {
      newOrder.splice(over.data.current.sortable.index + 1, 0, ...hiddenChildren[active.id]);
      setHiddenChildren({ ...hiddenChildren, [active.id]: null });
    }
    onDnd(newOrder);
  };

  /**
   * Reset state if the drag was canceled
   */
  const handleDragCancel = ({ active }: DragMoveEvent) => {
    setHiddenChildren({ ...hiddenChildren, [active.id]: null });
    setCategoriesList(productCategories);
  };

  /**
   * Hide children by their parent's id
   */
  const hideChildren = (parentId, parentIndex) => {
    const children = findChildren(parentId);
    if (children?.length) {
      const tmpList = [...categoriesList];
      tmpList.splice(parentIndex + 1, children.length);
      setCategoriesList(tmpList);
    }
  };

  /**
   * Find a category by its id
   */
  const findCategory = (id) => {
    return categoriesList.find(c => c.id === id);
  };
  /**
   * Find the children categories of a parent category by its id
   */
  const findChildren = (id) => {
    const displayedChildren = categoriesList.filter(c => c.parent_id === id);
    if (displayedChildren.length) {
      return displayedChildren;
    }
    return hiddenChildren[id];
  };
  /**
   * Find category's status by its id
   * single | parent | child
   */
  const categoryStatus = (id) => {
    const c = findCategory(id);
    if (!c.parent_id) {
      if (findChildren(id)?.length) {
        return 'parent';
      }
      return 'single';
    } else {
      return 'child';
    }
  };

  /**
   * Translate visual order into categories data positions
   */
  const indexToPosition = (sortedIds: number[]) => {
    const sort = sortedIds.map(sortedId => categoriesList.find(el => el.id === sortedId));
    const newPositions = sort.map(c => {
      if (typeof c.parent_id === 'number') {
        const parentIndex = sort.findIndex(el => el.id === c.parent_id);
        const currentIndex = sort.findIndex(el => el.id === c.id);
        return { ...c, position: (currentIndex - parentIndex - 1) };
      }
      return c;
    });
    return newPositions;
  };

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
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
                isChild={typeof category.parent_id === 'number'}
              />
            ))}
        </div>
      </SortableContext>
    </DndContext>
  );
};
