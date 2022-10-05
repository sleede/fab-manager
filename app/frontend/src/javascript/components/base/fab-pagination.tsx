import React from 'react';
import { CaretDoubleLeft, CaretLeft, CaretRight, CaretDoubleRight } from 'phosphor-react';

interface FabPaginationProps {
  pageCount: number,
  currentPage: number,
  selectPage: (page: number) => void
}

/**
 * Renders a pagination navigation
 */
export const FabPagination: React.FC<FabPaginationProps> = ({ pageCount, currentPage, selectPage }) => {
  return (
    <nav className='fab-pagination'>
      {currentPage - 2 > 1 &&
        <button type="button" onClick={() => selectPage(1)}><CaretDoubleLeft size={24} /></button>
      }
      {currentPage - 1 >= 1 &&
        <button type="button" onClick={() => selectPage(currentPage - 1)}><CaretLeft size={24} /></button>
      }
      {currentPage - 2 >= 1 &&
        <button type="button" onClick={() => selectPage(currentPage - 2)}>{currentPage - 2}</button>
      }
      {currentPage - 1 >= 1 &&
        <button type="button" onClick={() => selectPage(currentPage - 1)}>{currentPage - 1}</button>
      }
      <button type="button" className='is-active'>{currentPage}</button>
      {currentPage + 1 <= pageCount &&
        <button type="button" onClick={() => selectPage(currentPage + 1)}>{currentPage + 1}</button>
      }
      {currentPage + 2 <= pageCount &&
        <button type="button" onClick={() => selectPage(currentPage + 2)}>{currentPage + 2}</button>
      }
      {currentPage + 1 <= pageCount &&
        <button type="button" onClick={() => selectPage(currentPage + 1)}><CaretRight size={24} /></button>
      }
      {currentPage + 2 < pageCount &&
        <button type="button" onClick={() => selectPage(pageCount)}><CaretDoubleRight size={24} /></button>
      }
    </nav>
  );
};
