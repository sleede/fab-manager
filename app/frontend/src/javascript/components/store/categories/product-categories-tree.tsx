import React, { useEffect } from 'react';
import { useImmer } from 'use-immer';
import { ProductCategory } from '../../../models/product-category';
import { DndContext, KeyboardSensor, PointerSensor, useSensor, useSensors, closestCenter, DragMoveEvent } from '@dnd-kit/core';
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { restrictToWindowEdges } from '@dnd-kit/modifiers';
import { ProductCategoriesItem } from './product-categories-item';

interface ProductCategoriesTreeProps {
  productCategories: Array<ProductCategory>,
  onDnd: (list: Array<ProductCategory>, activeCategory: ProductCategory, position: number) => void,
  onSuccess: (message: string) => void,
  onError: (message: string) => void,
}

/**
 * This component shows a tree list of all Product's Categories
 */
export const ProductCategoriesTree: React.FC<ProductCategoriesTreeProps> = ({ productCategories, onDnd, onSuccess, onError }) => {
  const [categoriesList, setCategoriesList] = useImmer<ProductCategory[]>(productCategories);
  const [activeData, setActiveData] = useImmer<ActiveData>(initActiveData);
  const [extractedChildren, setExtractedChildren] = useImmer({});
  const [collapsed, setCollapsed] = useImmer<number[]>([]);

  // Initialize state from props
  useEffect(() => {
    setCategoriesList(productCategories);
  }, [productCategories]);

  // @dnd-kit config
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
    const activeStatus = getStatus(active.id);
    if (activeStatus === 'single') {
      if (Math.ceil(delta.x) > 32 && getStatus(over.id) !== 'child') {
        setActiveData(draft => {
          return { ...draft, offset: 'down' };
        });
      } else if (Math.ceil(delta.x) < -32 && getStatus(over.id) === 'child') {
        setActiveData(draft => {
          return { ...draft, offset: 'up' };
        });
      } else {
        setActiveData(draft => {
          return { ...draft, offset: null };
        });
      }
    }
    if (activeStatus === 'child') {
      if (Math.ceil(delta.x) > 32 && getStatus(over.id) !== 'child') {
        setActiveData(draft => {
          return { ...draft, offset: 'down' };
        });
      } else if (Math.ceil(delta.x) < -32 && getStatus(over.id) === 'child') {
        setActiveData(draft => {
          return { ...draft, offset: 'up' };
        });
      } else {
        setActiveData(draft => {
          return { ...draft, offset: null };
        });
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
    let droppedItem = getCategory(active.id);
    const activeStatus = getStatus(active.id);
    const overStatus = getStatus(over.id);
    let newPosition = getCategory(over.id).position;

    // [A]:Single dropped over [B]:Single
    if (activeStatus === 'single' && overStatus === 'single') {
      const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
      newOrder = newIdsOrder.map(sortedId => {
        let category = getCategory(sortedId);
        if (activeData.offset === 'down' && sortedId === active.id && activeData.index < newIndex && active.id !== over.id) {
          category = { ...category, parent_id: Number(over.id) };
          droppedItem = category;
        } else if (activeData.offset === 'down' && sortedId === active.id && (activeData.index > newIndex || active.id === over.id)) {
          category = { ...category, parent_id: getPreviousAdopter(over.id) };
          droppedItem = category;
        }
        return category;
      });
    }

    // [A]:Child dropped over [B]:Single
    if ((activeStatus === 'child') && overStatus === 'single') {
      const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
      newOrder = newIdsOrder.map(sortedId => {
        let category = getCategory(sortedId);
        if (activeData.offset === 'down' && sortedId === active.id && activeData.index < newIndex) {
          category = { ...category, parent_id: Number(over.id) };
          droppedItem = category;
          newPosition = 0;
        } else if (activeData.offset === 'down' && sortedId === active.id && activeData.index > newIndex) {
          category = { ...category, parent_id: getPreviousAdopter(over.id) };
          droppedItem = category;
          newPosition = getChildren(getPreviousAdopter(over.id))?.length || 0;
        } else if (sortedId === active.id) {
          category = { ...category, parent_id: null };
          droppedItem = category;
        }
        return category;
      });
    }

    // [A]:Single || [A]:Child dropped over…
    if (activeStatus === 'single' || activeStatus === 'child') {
      // [B]:Parent
      if (overStatus === 'parent') {
        const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
        if (activeData.index < newIndex) {
          newOrder = newIdsOrder.map(sortedId => {
            let category = getCategory(sortedId);
            if (sortedId === active.id) {
              category = { ...category, parent_id: Number(over.id) };
              droppedItem = category;
              newPosition = 0;
            }
            return category;
          });
        } else if (activeData.index > newIndex) {
          newOrder = newIdsOrder.map(sortedId => {
            let category = getCategory(sortedId);
            if (sortedId === active.id && !activeData.offset) {
              category = { ...category, parent_id: null };
              droppedItem = category;
            } else if (sortedId === active.id && activeData.offset === 'down') {
              category = { ...category, parent_id: getPreviousAdopter(over.id) };
              droppedItem = category;
              newPosition = getChildren(getPreviousAdopter(over.id))?.length || 0;
            }
            return category;
          });
        }
      }
      // [B]:Child
      if (overStatus === 'child') {
        if (activeData.offset === 'up') {
          const lastChildIndex = newOrder.findIndex(c => c.id === getChildren(getCategory(over.id).parent_id).pop().id);
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, lastChildIndex);
          newOrder = newIdsOrder.map(sortedId => {
            let category = getCategory(sortedId);
            if (sortedId === active.id) {
              category = { ...category, parent_id: null };
              droppedItem = category;
            }
            return category;
          });
        } else {
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => {
            let category = getCategory(sortedId);
            if (sortedId === active.id) {
              category = { ...category, parent_id: getCategory(over.id).parent_id };
              droppedItem = category;
            }
            return category;
          });
        }
      }
    }

    // [A]:Parent dropped over…
    if (activeStatus === 'parent') {
      // [B]:Single
      if (overStatus === 'single') {
        const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
        newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
      }
      // [B]:Parent
      if (overStatus === 'parent') {
        if (activeData.index < newIndex) {
          newIndex = newOrder.findIndex(c => c.id === getChildren(over.id).pop().id);
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
        } else {
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
        }
      }
      // [B]:Child
      if (overStatus === 'child') {
        if (activeData.index < newIndex) {
          const parent = newOrder.find(c => c.id === getCategory(over.id).parent_id);
          newIndex = newOrder.findIndex(c => c.id === getChildren(parent.id).pop().id);
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
        } else {
          newIndex = currentIdsOrder.indexOf(getCategory(over.id).parent_id);
          const newIdsOrder = arrayMove(currentIdsOrder, activeData.index, newIndex);
          newOrder = newIdsOrder.map(sortedId => getCategory(sortedId));
        }
      }
      // insert children back
      newOrder = showChildren(active.id, newOrder, newIndex);
    }

    setActiveData(initActiveData);
    onDnd(newOrder, droppedItem, newPosition);
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
   * Get previous category that can have children
   */
  const getPreviousAdopter = (overId) => {
    const reversedList = [...categoriesList].reverse();
    const dropIndex = reversedList.findIndex(c => c.id === overId);
    const adopter = reversedList.find((c, index) => index > dropIndex && !c.parent_id)?.id;
    return adopter || null;
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
   * Toggle parent category by hiding/showing its children
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
                offset={category.id === activeData.category?.id ? activeData?.offset : null}
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
  offset: 'up' | 'down' | null
}
const initActiveData: ActiveData = {
  index: null,
  category: null,
  status: null,
  children: [],
  offset: null
};
